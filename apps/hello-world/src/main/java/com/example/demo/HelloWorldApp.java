package com.example.demo;

import java.util.Optional;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.http.client.HttpComponentsClientHttpRequestFactory;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.client.RestClient;

import lombok.AllArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@AllArgsConstructor
@Controller
class GreetingController {

	RestClient salutationProviderClient;

	@GetMapping("/")
	public String hello(@RequestParam Optional<String> greetee, Model model) {

		if (greetee.isEmpty()) {
			return "greeting";
		}
		log.info("Greeting the user: {}", greetee.get());

		try {
			var salutation = salutationProviderClient
					.get()
					.uri("/get-salutation-for-name?name=" + greetee.get())
					.retrieve()
					.body(String.class);

			var greeting = salutation + " " + greetee.get() + "!";

			model.addAttribute("greeting", greeting);
		} catch (Exception e) {
			log.warn("Error while greeting the user", e);
			model.addAttribute("error", "Error while greeting the user");
		}

		return "greeting";
	}
}

@Slf4j
@SpringBootApplication
public class HelloWorldApp {

	public static void main(String[] args) {
		log.info("Starting the hello world app");
		SpringApplication.run(HelloWorldApp.class, args);
	}

	@Bean
	public RestClient salutationProviderClient(@Value("${salutation-provider.url}") String greetingProviderUrl) {
		return RestClient.builder()
		.requestFactory(new HttpComponentsClientHttpRequestFactory()) // 
		.baseUrl(greetingProviderUrl).build();
	}

}
