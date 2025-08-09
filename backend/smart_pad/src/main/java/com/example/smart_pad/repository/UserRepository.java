package com.example.smart_pad.repository;

import com.example.smart_pad.domain.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {
    // username으로 사용자를 찾는 메서드 (JPA가 이름만 보고 자동으로 쿼리 생성)
    Optional<User> findByUsername(String username);
}
