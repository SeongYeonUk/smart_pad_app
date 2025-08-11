package com.example.smart_pad.repository;

import com.example.smart_pad.domain.AdminDetail;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface AdminDetailRepository extends JpaRepository<AdminDetail, Long> {
    // User ID로 AdminDetail을 찾는 메서드 추가
    Optional<AdminDetail> findByUserId(Long userId);
}