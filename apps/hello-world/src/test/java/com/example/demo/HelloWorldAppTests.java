package com.example.demo;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest(properties = "salutation-provider.url=http://localhost:8080")
class HelloWorldAppTests {

	@Test
	void contextLoads() {
	}

}
