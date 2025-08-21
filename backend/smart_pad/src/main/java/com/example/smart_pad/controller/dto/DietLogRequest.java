package com.example.smart_pad.controller.dto;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;

@Getter @Setter
public class DietLogRequest {
    private Long id; // 식단 기록 ID
    private Long userId; // 사용자 ID

    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd")
    private LocalDate date;

    private String mealType;
    private String mainDish;
    private String subDish;
    private Integer proteinGrams;
}
