package com.example.smart_pad.controller;

import com.example.smart_pad.controller.dto.SensorDataRequest;
import com.example.smart_pad.domain.PatientDetail;
import com.example.smart_pad.domain.SensorData;
import com.example.smart_pad.service.AuthService;
import com.example.smart_pad.service.SensorDataService;
import jakarta.annotation.security.PermitAll;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/sensor-data")
public class SensorDataController {

    private final SensorDataService sensorDataService;
    private final AuthService authService;

    @Value("${sensor.default-patient-id:#{null}}")
    private Long defaultPatientId; // 없으면 null

    public SensorDataController(SensorDataService sensorDataService, AuthService authService) {
        this.sensorDataService = sensorDataService;
        this.authService = authService;
    }

    // (1) 경로변수 방식: POST /api/sensor-data/{patientId}
    @PermitAll
    @PostMapping("/{patientId}")
    public ResponseEntity<?> receiveSensorDataPath(
            @PathVariable Long patientId,
            @Valid @RequestBody SensorDataRequest request,
            Authentication authentication
    ) {
        return doIngest(request, patientId, null, authentication);
    }

    // (2) 쿼리/헤더/기본값 방식: POST /api/sensor-data
    @PermitAll
    @PostMapping
    public ResponseEntity<?> receiveSensorData(
            @Valid @RequestBody SensorDataRequest request,
            @RequestParam(name = "patientId", required = false) Long patientIdQuery,
            @RequestHeader(name = "X-Patient-Id", required = false) Long patientIdHeader,
            Authentication authentication
    ) {
        return doIngest(request, patientIdQuery, patientIdHeader, authentication);
    }

    private ResponseEntity<?> doIngest(
            SensorDataRequest request,
            Long patientIdQuery,
            Long patientIdHeader,
            Authentication authentication
    ) {
        PatientDetail patient;

        if (authentication != null && authentication.isAuthenticated()) {
            Long userId = authService.getUserIdFromAuthentication(authentication);
            patient = authService.getPatientDetailById(userId);
            if (patient == null) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body("환자 정보를 찾을 수 없습니다.");
            }
        } else {
            Long resolvedPatientId = firstNonNull(
                    patientIdQuery,
                    patientIdHeader,
                    request.getPatientId(),          // 바디
                    defaultPatientId,                // application.properties
                    getenvLong("DEFAULT_PATIENT_ID") // 환경변수
            );
            if (resolvedPatientId == null) {
                return ResponseEntity.badRequest().body(
                        "익명 요청에는 환자 식별자가 필요합니다. " +
                                "[경로 /api/sensor-data/{patientId}] 또는 [쿼리 patientId] 또는 [헤더 X-Patient-Id] " +
                                "또는 [바디 patientId] 또는 [sensor.default-patient-id / DEFAULT_PATIENT_ID] 중 하나를 사용하세요."
                );
            }
            patient = authService.getPatientDetailById(resolvedPatientId);
            if (patient == null) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body("환자 정보를 찾을 수 없습니다.");
            }
        }

        // 서비스 시그니처(Integer, Integer, Integer, PatientDetail)에 맞춰 변환
        Integer pressureInt = request.getPressure();
        Integer temperatureInt = (request.getTemperature() == null)
                ? null : (int) Math.round(request.getTemperature());
        Integer humidityInt = (request.getHumidity() == null)
                ? null : (int) Math.round(request.getHumidity());

        SensorData saved = sensorDataService.saveAndProcessSensorData(
                pressureInt,
                temperatureInt,
                humidityInt,
                patient
        );

        return ResponseEntity.status(HttpStatus.ACCEPTED).body(saved.getId());
    }

    @GetMapping("/latest")
    public ResponseEntity<?> getLatestSensorData(
            @RequestParam(name = "limit", defaultValue = "1") int limit,
            Authentication authentication
    ) {
        if (authentication == null || !authentication.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("로그인 정보가 유효하지 않습니다.");
        }

        if (limit < 1) limit = 1;
        if (limit > 600) limit = 600;

        Long userId = authService.getUserIdFromAuthentication(authentication);
        PatientDetail patient = authService.getPatientDetailById(userId);
        if (patient == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("환자 정보를 찾을 수 없습니다.");
        }

        List<SensorData> result = sensorDataService.getLatestForPatient(patient, limit);
        return ResponseEntity.ok(result);
    }

    // ===== util =====
    private static Long firstNonNull(Long... vals) {
        for (Long v : vals) if (v != null) return v;
        return null;
    }
    private static Long getenvLong(String key) {
        try {
            String s = System.getenv(key);
            return (s == null || s.isBlank()) ? null : Long.parseLong(s.trim());
        } catch (Exception e) { return null; }
    }
}
