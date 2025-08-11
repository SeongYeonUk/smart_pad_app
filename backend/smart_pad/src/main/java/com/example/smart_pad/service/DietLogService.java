package com.example.smart_pad.service;

import com.example.smart_pad.controller.dto.DietLogRequest;
import com.example.smart_pad.controller.dto.DietLogResponse;
import com.example.smart_pad.domain.DietLog;
import com.example.smart_pad.domain.User;
import com.example.smart_pad.repository.DietLogRepository;
import com.example.smart_pad.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class DietLogService {

    private final DietLogRepository dietLogRepository;
    private final UserRepository userRepository;

    /**
     * 식단 기록 저장
     */
    @Transactional
    public void saveDietLog(Long userId, DietLogRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));

        DietLog dietLog = new DietLog();
        dietLog.setUser(user);
        dietLog.setDate(request.getDate());
        dietLog.setMealType(request.getMealType());
        dietLog.setMainDish(request.getMainDish());
        dietLog.setSubDish(request.getSubDish());

        dietLogRepository.save(dietLog);
    }

    // ▼▼▼ 식단 기록을 저장하고 DTO로 반환하는 새로운 메서드를 추가합니다.
    @Transactional
    public DietLogResponse saveDietLogAndReturnDto(Long userId, DietLogRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));

        DietLog dietLog = new DietLog();
        dietLog.setUser(user);
        dietLog.setDate(request.getDate());
        dietLog.setMealType(request.getMealType());
        dietLog.setMainDish(request.getMainDish());
        dietLog.setSubDish(request.getSubDish());

        DietLog savedLog = dietLogRepository.save(dietLog);

        return DietLogResponse.builder()
                .id(savedLog.getId())
                .date(savedLog.getDate())
                .mealType(savedLog.getMealType())
                .mainDish(savedLog.getMainDish())
                .subDish(savedLog.getSubDish())
                .build();
    }

    /**
     * 특정 사용자의 모든 식단 기록 조회
     */
    @Transactional(readOnly = true)
    public List<DietLogResponse> getDietLogs(Long userId) {
        List<DietLog> dietLogs = dietLogRepository.findByUserIdOrderByDateDesc(userId);

        return dietLogs.stream()
                .map(log -> DietLogResponse.builder()
                        .id(log.getId())
                        .date(log.getDate())
                        .mealType(log.getMealType())
                        .mainDish(log.getMainDish())
                        .subDish(log.getSubDish())
                        .build())
                .collect(Collectors.toList());
    }
}
