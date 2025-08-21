package com.example.smart_pad.repository;

import com.example.smart_pad.domain.AdminDetail;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface AdminDetailRepository extends JpaRepository<AdminDetail, Long> {

    /**
     * User 엔티티의 PK(ID)로 AdminDetail 조회
     * - AdminDetail.user.id 를 기준으로 검색
     */
    Optional<AdminDetail> findByUser_Id(Long userId);

    /**
     * User 엔티티의 username으로 AdminDetail 조회
     */
    Optional<AdminDetail> findByUser_Username(String username);

    /**
     * 특정 User ID를 가진 AdminDetail 존재 여부 확인
     */
    boolean existsByUser_Id(Long userId);
}
