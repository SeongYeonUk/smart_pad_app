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
    private Long defaultPatientId; // Use a default patient ID if no auth is provided

    public SensorDataController(SensorDataService sensorDataService, AuthService authService) {
        this.sensorDataService = sensorDataService;
        this.authService = authService;
    }

    /**
     * (익명/인증 모두 허용) 센서데이터 수집
     * - 로그인한 사용자는 자동으로 자신의 환자 레코드에 저장
     * - 익명 요청은 application.properties에 설정된 default-patient-id에 저장
     *
     * POST /api/sensor-data
     * Body: { "pressure": 0.., "temperature": 23.1, "humidity": 54.2 }
     */
    @PermitAll
    @PostMapping
    public ResponseEntity<?> receiveSensorData(
            @Valid @RequestBody SensorDataRequest request,
            Authentication authentication
    ) {
        PatientDetail patient;

        // If an authenticated user is logged in, use their details
        if (authentication != null && authentication.isAuthenticated()) {
            Long userId = authService.getUserIdFromAuthentication(authentication);
            patient = authService.getPatientDetailById(userId);
            if (patient == null) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Patient not found.");
            }
        } else {
            // For anonymous requests, use the default patient ID from properties
            if (defaultPatientId == null) {
                return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                        .body("Anonymous requests require a default patient ID configured in application.properties.");
            }
            patient = authService.getPatientDetailById(defaultPatientId);
            if (patient == null) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Default patient not found.");
            }
        }

        // Convert and save sensor data
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

    /**
     * (인증 필수) 최신 센서데이터 조회
     * GET /api/sensor-data/latest?limit=1
     * Authorization: Bearer <JWT>
     */
    @GetMapping("/latest")
    public ResponseEntity<?> getLatestSensorData(
            @RequestParam(name = "limit", defaultValue = "1") int limit,
            Authentication authentication
    ) {
        if (authentication == null || !authentication.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("로그인이 필요합니다.");
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
}
