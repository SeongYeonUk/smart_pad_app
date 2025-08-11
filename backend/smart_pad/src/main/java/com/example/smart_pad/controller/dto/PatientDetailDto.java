package com.example.smart_pad.controller.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class PatientDetailDto {
    // Flutter 앱에서 보낸 JSON의 키(key) 이름과 일치해야 합니다.
    private Double weight;
    private String ageRange;
    private String sensoryPerception;
    private String activityLevel;
    private String movementLevel;
}