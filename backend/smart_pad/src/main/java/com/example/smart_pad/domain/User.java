package com.example.smart_pad.domain;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "users")
@Getter
@Setter // Setter 어노테이션이 있어야 setName() 메서드가 동작합니다.
@Builder
@AllArgsConstructor
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "user_id")
    private Long id;

    @Column(nullable = false, unique = true)
    private String username;

    @Column(nullable = false)
    private String password;

    @Column(nullable = false)
    private String name;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private UserRole role;

    // ▼▼▼ 환자 상세 정보 필드 추가 (User는 연관관계의 주인이 아님) ▼▼▼
    @JsonIgnore // JSON 직렬화 시 무시하여 순환 참조를 방지합니다.
    @OneToOne(mappedBy = "user", fetch = FetchType.LAZY)
    private PatientDetail patientDetail;

    // ▼▼▼ 관리자 상세 정보 필드 추가 (User는 연관관계의 주인이 아님) ▼▼▼
    @JsonIgnore // JSON 직렬화 시 무시하여 순환 참조를 방지합니다.
    @OneToOne(mappedBy = "user", fetch = FetchType.LAZY)
    private AdminDetail adminDetail;
}