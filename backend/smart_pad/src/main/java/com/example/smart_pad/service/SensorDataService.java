package com.example.smart_pad.service;

import com.example.smart_pad.domain.PatientDetail;
import com.example.smart_pad.domain.SensorData;
import com.example.smart_pad.repository.SensorDataRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class SensorDataService {

    private final SensorDataRepository sensorDataRepository;
    private final SimpMessagingTemplate messagingTemplate;

    // 보존 상한: 10분 ~= 600초 (1초 간격 수집)
    private static final int MAX_KEEP = 600;

    /**
     * 센서 데이터 저장 + 실시간 전송 + 보관 정책(10분 초과/600개 초과) 정리
     */
    @Transactional
    public SensorData saveAndProcessSensorData(Integer pressure,
                                               Integer temperature,
                                               Integer humidity,
                                               PatientDetail patient) {

        // 1) 생성 & 저장 (timestamp는 now)
        SensorData d = new SensorData();
        d.setPressure(pressure);
        d.setTemperature(temperature);
        d.setHumidity(humidity);
        d.setTimestamp(LocalDateTime.now());
        d.setPatient(patient);

        SensorData saved = sensorDataRepository.save(d);

        // 2) 실시간 전송 (WebSocketConfig의 broker 설정과 경로 일치)
        messagingTemplate.convertAndSend("/topic/sensordata/" + patient.getId(), saved);

        // 3) 보관 정책 적용
        pruneOldAndExcess(patient);

        return saved;
    }

    /**
     * 환자 기준 최신 N개 조회 (timestamp DESC)
     */
    @Transactional(readOnly = true)
    public List<SensorData> getLatestForPatient(PatientDetail patient, int limit) {
        int pageSize = Math.max(1, Math.min(limit, MAX_KEEP));
        var page = sensorDataRepository.findByPatient(
                patient,
                PageRequest.of(0, pageSize, Sort.by(Sort.Direction.DESC, "timestamp"))
        );
        return page.getContent();
    }

    /**
     * 10분 초과 데이터 삭제 + 600개 초과분 삭제(오래된 것부터)
     */
    private void pruneOldAndExcess(PatientDetail patient) {
        // 10분 초과 데이터 일괄 삭제
        sensorDataRepository.deleteByPatientAndTimestampBefore(
                patient,
                LocalDateTime.now().minusMinutes(10)
        );

        // 600개 초과 시 오래된 데이터 삭제
        long count = sensorDataRepository.countByPatient(patient);
        if (count > MAX_KEEP) {
            int toRemove = (int) (count - MAX_KEEP);
            var oldPage = sensorDataRepository.findByPatient(
                    patient,
                    PageRequest.of(0, toRemove, Sort.by(Sort.Direction.ASC, "timestamp"))
            );
            if (!oldPage.isEmpty()) {
                sensorDataRepository.deleteAll(oldPage.getContent());
            }
        }
    }
}
