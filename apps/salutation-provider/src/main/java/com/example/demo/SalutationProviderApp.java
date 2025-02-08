package com.example.demo;

import static java.time.LocalDateTime.now;

import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.data.repository.CrudRepository;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import jakarta.persistence.Basic;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Entity
@Data
@EqualsAndHashCode(of = "id")
@NoArgsConstructor
@AllArgsConstructor
class Salutation {

	@Id
	Integer id;
	@Basic
	String text;
}

interface SalutationRepository extends CrudRepository<Salutation, Integer> {
}

@Slf4j
@RestController
@AllArgsConstructor
class SalutationController {

	SalutationRepository repo;

	@GetMapping("/get-salutation-for-name")
	public String salutation(@RequestParam String name) {

		var randomId = name.hashCode() % 3; // random but deterministic ;)
		
		log.info("Looking up salutation with id {}", randomId);
		
		return repo.findById(randomId).get().getText();
	}
}

@Slf4j
@SpringBootApplication
public class SalutationProviderApp {

	@Bean
	ApplicationRunner init(SalutationRepository repo) {
		
		return _ -> {
			log.info("Initializing salutations");
			repo.save(new Salutation(0, "Hello"));
			repo.save(new Salutation(1, "Howdy"));
			repo.save(new Salutation(2, "What's crackin"));
			log.info("Salutations initialized");
		};
	}
	public static void main(String[] args) {
		SpringApplication.run(SalutationProviderApp.class, args);
	}

}
