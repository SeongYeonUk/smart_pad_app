package com.example.smart_pad.repository;

import com.example.smart_pad.domain.DietLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface DietLogRepository extends JpaRepository<DietLog, Long> {
    // 특정 사용자의 모든 식단 기록을 날짜 내림차순으로 조회하는 메서드
    List<DietLog> findByUserIdOrderByDateDesc(Long userId);
}
