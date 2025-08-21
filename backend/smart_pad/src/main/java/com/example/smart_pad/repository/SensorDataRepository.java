package com.example.smart_pad.repository;

import com.example.smart_pad.domain.PatientDetail;
import com.example.smart_pad.domain.SensorData;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;

@Repository
public interface SensorDataRepository extends JpaRepository<SensorData, Long> {

    /**
     * 환자별 데이터 페이징 조회
     * - 오래된 것/최신 것 정렬은 Pageable에서 Sort로 지정
     */
    Page<SensorData> findByPatient(PatientDetail patient, Pageable pageable);

    /**
     * 환자별 전체 개수
     */
    long countByPatient(PatientDetail patient);

    /**
     * 환자별 특정 시각 이전 데이터 일괄 삭제
     */
    long deleteByPatientAndTimestampBefore(PatientDetail patient, LocalDateTime before);
}
