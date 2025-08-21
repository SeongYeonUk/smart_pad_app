package com.example.smart_pad.repository;

import com.example.smart_pad.domain.PatientDetail;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface PatientDetailRepository extends JpaRepository<PatientDetail, Long> {

    /**
     * User 엔티티의 PK(ID)로 PatientDetail 조회
     * - PatientDetail.user.id 를 기준으로 검색
     */
    Optional<PatientDetail> findByUser_Id(Long userId);

    /**
     * User 엔티티의 username으로 PatientDetail 조회
     */
    Optional<PatientDetail> findByUser_Username(String username);

    /**
     * 특정 User ID를 가진 PatientDetail 존재 여부 확인
     */
    boolean existsByUser_Id(Long userId);
}
