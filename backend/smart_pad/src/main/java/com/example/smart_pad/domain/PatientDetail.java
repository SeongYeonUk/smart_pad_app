package com.example.smart_pad.domain;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "patient_detail")
@Getter
@Setter
@NoArgsConstructor
public class PatientDetail {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // ▼▼▼ User가 필드에 대한 연관관계의 주인임 ▼▼▼
    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", referencedColumnName = "user_id")
    @JsonIgnore // JSON 직렬화 시 무시하여 순환 참조를 방지합니다.
    private User user;

    @Column(name = "weight")
    private Double weight;

    @Column(name = "age_range")
    private String ageRange;

    @Column(name = "sensory_perception")
    private String sensoryPerception;

    @Column(name = "activity_level")
    private String activityLevel;

    @Column(name = "movement_level")
    private String movementLevel;
}