package com.example.smart_pad.controller.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class UpdateProfileRequest {
    private String name;
    private PatientDetailDto patientDetail;
    private AdminDetailDto adminDetail;
}