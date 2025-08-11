package com.example.smart_pad.repository;

import com.example.smart_pad.domain.PatientDetail;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface PatientDetailRepository extends JpaRepository<PatientDetail, Long> {
    // User ID로 PatientDetail을 찾는 메서드 추가
    Optional<PatientDetail> findByUserId(Long userId);
}