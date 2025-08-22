package com.example.smart_pad.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    @Override
    public void configureMessageBroker(MessageBrokerRegistry config) {
        // 클라이언트가 서버로 메시지를 보낼 때 사용하는 prefix.
        // 예를 들어, /app/send-data 로 메시지를 보낼 수 있습니다.
        config.setApplicationDestinationPrefixes("/app");

        // 서버가 클라이언트에게 메시지를 보낼 때 사용하는 prefix.
        // 예를 들어, /topic/sensordata 로 메시지를 구독할 수 있습니다.
        config.enableSimpleBroker("/topic");
    }

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        // WebSocket 연결을 위한 엔드포인트 설정
        // 클라이언트는 이 URL로 WebSocket 연결을 시작합니다.
        // 앱에서 사용하는 경로인 '/ws/sensor'로 수정했습니다.
        registry.addEndpoint("/ws/sensor").setAllowedOriginPatterns("*");
    }
}
