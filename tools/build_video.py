#!/usr/bin/env python3
"""Generador de video de Remotion a través del servidor MCP oficial.

Crea el bundle del proyecto y genera el reproductor interactivo
'video_presentacion.html' en la raíz del repositorio.
"""

import json
import os
import urllib.request

files = {}

files['/src/components/Background.tsx'] = """import React from 'react';
import { AbsoluteFill, useCurrentFrame, interpolate } from 'remotion';

export const Background: React.FC = () => {
  const frame = useCurrentFrame();
  const orb1Y = interpolate(Math.sin(frame * 0.04), [-1, 1], [-40, 40]);
  const orb2X = interpolate(Math.cos(frame * 0.03), [-1, 1], [-60, 60]);

  return (
    <AbsoluteFill
      style={{
        backgroundColor: '#07160E',
        overflow: 'hidden',
        zIndex: 0,
      }}
    >
      <div
        style={{
          position: 'absolute',
          width: '100%',
          height: '100%',
          background: 'radial-gradient(circle at 50% 20%, #133A24 0%, #08170F 70%, #040C07 100%)',
        }}
      />
      <div
        style={{
          position: 'absolute',
          top: 150 + orb1Y,
          left: '15%',
          width: 550,
          height: 550,
          borderRadius: '50%',
          background: 'radial-gradient(circle, rgba(46, 125, 50, 0.28) 0%, rgba(46, 125, 50, 0) 70%)',
          filter: 'blur(40px)',
          pointerEvents: 'none',
        }}
      />
      <div
        style={{
          position: 'absolute',
          bottom: 100,
          right: '12%',
          transform: `translateX(${orb2X}px)`,
          width: 650,
          height: 650,
          borderRadius: '50%',
          background: 'radial-gradient(circle, rgba(245, 158, 11, 0.16) 0%, rgba(245, 158, 11, 0) 70%)',
          filter: 'blur(50px)',
          pointerEvents: 'none',
        }}
      />
      <div
        style={{
          position: 'absolute',
          width: '100%',
          height: '100%',
          backgroundImage:
            'linear-gradient(rgba(255, 255, 255, 0.03) 1px, transparent 1px), linear-gradient(90deg, rgba(255, 255, 255, 0.03) 1px, transparent 1px)',
          backgroundSize: '40px 40px',
          opacity: 0.8,
        }}
      />
    </AbsoluteFill>
  );
};
"""

files['/src/scenes/IntroScene.tsx'] = """import React from 'react';
import { AbsoluteFill, useCurrentFrame, useVideoConfig, spring, interpolate } from 'remotion';

export const IntroScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const titleSpring = spring({ frame, fps, delay: 10, config: { damping: 14, stiffness: 120 } });
  const badgeSpring = spring({ frame, fps, delay: 2, config: { damping: 15 } });
  const subtitleSpring = spring({ frame, fps, delay: 22, config: { damping: 16 } });
  const pillsSpring = spring({ frame, fps, delay: 35, config: { damping: 18 } });

  const titleScale = interpolate(titleSpring, [0, 1], [0.8, 1]);
  const titleOpacity = interpolate(titleSpring, [0, 1], [0, 1]);
  const floatY = Math.sin(frame * 0.08) * 8;

  return (
    <AbsoluteFill
      style={{
        justifyContent: 'center',
        alignItems: 'center',
        padding: '0 80px',
        fontFamily: 'system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
      }}
    >
      <div
        style={{
          opacity: badgeSpring,
          transform: `scale(${badgeSpring})`,
          backgroundColor: 'rgba(46, 125, 50, 0.28)',
          border: '1.5px solid rgba(82, 183, 136, 0.6)',
          borderRadius: 30,
          padding: '8px 24px',
          color: '#52B788',
          fontSize: 22,
          fontWeight: 700,
          letterSpacing: 2,
          textTransform: 'uppercase',
          marginBottom: 24,
          boxShadow: '0 0 20px rgba(82, 183, 136, 0.25)',
        }}
      >
        🎮 Proyecto Educativo Oficial · COBAEM CEMSaD 22
      </div>
      <div
        style={{
          opacity: titleOpacity,
          transform: `scale(${titleScale}) translateY(${floatY}px)`,
          textAlign: 'center',
          fontSize: 88,
          fontWeight: 900,
          letterSpacing: -1.5,
          lineHeight: 1.08,
          background: 'linear-gradient(135deg, #FFFFFF 20%, #74C69D 60%, #FBBF24 100%)',
          WebkitBackgroundClip: 'text',
          WebkitTextFillColor: 'transparent',
          marginBottom: 20,
          textShadow: '0 10px 40px rgba(0,0,0,0.4)',
        }}
      >
        CAMPEONES DE LOS VALORES
      </div>
      <div
        style={{
          opacity: subtitleSpring,
          transform: `translateY(${interpolate(subtitleSpring, [0, 1], [25, 0])}px)`,
          fontSize: 32,
          fontWeight: 400,
          color: '#D8F3DC',
          textAlign: 'center',
          maxWidth: 1100,
          lineHeight: 1.4,
          marginBottom: 44,
        }}
      >
        Videojuego 2D en perspectiva 3/4 & Visor Arquitectónico CAD/BIM 3D
        <br />
        <span style={{ color: '#FBBF24', fontWeight: 600 }}>
          Plantel CEMSaD 22 ENTHAVI · Escala Unificada 1m = 40px
        </span>
      </div>
      <div
        style={{
          opacity: pillsSpring,
          transform: `translateY(${interpolate(pillsSpring, [0, 1], [30, 0])}px)`,
          display: 'flex',
          gap: 16,
          flexWrap: 'wrap',
          justifyContent: 'center',
        }}
      >
        {[
          '⚡ Godot Engine 4.7',
          '🛡️ Filosofía de No Violencia',
          '📐 6 Escenarios a Escala Real',
          '📱 Versión Android con Joysticks',
          '📦 Release v1.0 Lista',
        ].map((pill, i) => (
          <div
            key={i}
            style={{
              backgroundColor: 'rgba(255, 255, 255, 0.08)',
              border: '1px solid rgba(255, 255, 255, 0.16)',
              borderRadius: 20,
              padding: '10px 22px',
              fontSize: 20,
              color: '#FFFFFF',
              fontWeight: 500,
              backdropFilter: 'blur(8px)',
            }}
          >
            {pill}
          </div>
        ))}
      </div>
    </AbsoluteFill>
  );
};
"""

files['/src/scenes/ValuesScene.tsx'] = """import React from 'react';
import { AbsoluteFill, useCurrentFrame, useVideoConfig, spring, interpolate } from 'remotion';

export const ValuesScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const headerSpring = spring({ frame, fps, delay: 5, config: { damping: 16 } });

  const pairs = [
    { bad: 'Grosería & Hostilidad', good: '¡Amabilidad & Buen Trato!', color: '#F59E0B', icon: '🤝' },
    { bad: 'Acoso Escolar', good: '¡Respeto y Dignidad!', color: '#3B82F6', icon: '💖' },
    { bad: 'Bullying & Exclusión', good: '¡Empatía e Inclusión!', color: '#10B981', icon: '🌟' },
  ];

  return (
    <AbsoluteFill
      style={{
        padding: '70px 100px',
        justifyContent: 'center',
        alignItems: 'center',
        fontFamily: 'system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
      }}
    >
      <div
        style={{
          opacity: headerSpring,
          transform: `translateY(${interpolate(headerSpring, [0, 1], [-20, 0])}px)`,
          textAlign: 'center',
          marginBottom: 50,
        }}
      >
        <div style={{ color: '#52B788', fontSize: 22, fontWeight: 700, letterSpacing: 2, textTransform: 'uppercase', marginBottom: 8 }}>
          LECTURA DEL README · FILOSOFÍA FORMATIVA
        </div>
        <div style={{ color: '#FFFFFF', fontSize: 58, fontWeight: 800 }}>
          Resolución Constructiva sin Violencia
        </div>
        <div style={{ color: '#B7E4C7', fontSize: 24, marginTop: 10, maxWidth: 960 }}>
          Los antivalores no son destruidos ni aniquilados: al recibir proyectiles de virtud, son <span style={{ color: '#FBBF24', fontWeight: 700 }}>redimidos pacíficamente</span>.
        </div>
      </div>

      <div style={{ display: 'flex', gap: 32, width: '100%', maxWidth: 1400, justifyContent: 'center' }}>
        {pairs.map((p, idx) => {
          const cardSpring = spring({ frame, fps, delay: 18 + idx * 12, config: { damping: 14 } });
          const cardScale = interpolate(cardSpring, [0, 1], [0.85, 1]);
          const cardOpacity = interpolate(cardSpring, [0, 1], [0, 1]);

          return (
            <div
              key={idx}
              style={{
                flex: 1,
                opacity: cardOpacity,
                transform: `scale(${cardScale}) translateY(${interpolate(cardSpring, [0, 1], [40, 0])}px)`,
                backgroundColor: 'rgba(16, 42, 28, 0.85)',
                border: '1.5px solid rgba(82, 183, 136, 0.4)',
                borderRadius: 24,
                padding: '36px 28px',
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                boxShadow: '0 20px 40px rgba(0,0,0,0.3)',
                position: 'relative',
              }}
            >
              <div
                style={{
                  backgroundColor: 'rgba(239, 68, 68, 0.15)',
                  border: '1px solid rgba(239, 68, 68, 0.4)',
                  color: '#FCA5A5',
                  padding: '8px 18px',
                  borderRadius: 16,
                  fontSize: 18,
                  fontWeight: 600,
                  marginBottom: 20,
                }}
              >
                Antivalor: {p.bad}
              </div>
              <div style={{ fontSize: 36, color: '#52B788', margin: '8px 0' }}>⬇️</div>
              <div
                style={{
                  width: '100%',
                  backgroundColor: 'rgba(46, 125, 50, 0.35)',
                  border: `2px solid ${p.color}`,
                  borderRadius: 18,
                  padding: '20px 16px',
                  textAlign: 'center',
                  marginTop: 12,
                }}
              >
                <div style={{ fontSize: 40, marginBottom: 8 }}>{p.icon}</div>
                <div style={{ color: '#FFFFFF', fontSize: 24, fontWeight: 800 }}>{p.good}</div>
                <div style={{ color: p.color, fontSize: 16, fontWeight: 600, marginTop: 4 }}>
                  REGENERACIÓN PACÍFICA
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </AbsoluteFill>
  );
};
"""

files['/src/scenes/ScenariosScene.tsx'] = """import React from 'react';
import { AbsoluteFill, useCurrentFrame, useVideoConfig, spring, interpolate } from 'remotion';

export const ScenariosScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const headerSpring = spring({ frame, fps, delay: 4, config: { damping: 16 } });

  const buildings = [
    { id: '1', name: 'Acceso y Laboratorio', area: '183 m²', type: 'Edificio D' },
    { id: '2', name: 'Cafetería y Aulas 1-2', area: '339 m²', type: 'Edificio A' },
    { id: '3', name: 'Plaza Cívica & Escalinata', area: '748 m²', type: 'Nivel +4m' },
    { id: '4', name: 'Aulas 3-4 y Biblioteca', area: '340 m²', type: 'Edificio B' },
    { id: '5', name: 'Dirección y Cómputo', area: '625 m²', type: 'Edificio C' },
    { id: '6', name: 'Cancha Multideportiva', area: '540 m²', type: 'Patio Central' },
  ];

  return (
    <AbsoluteFill
      style={{
        padding: '60px 100px',
        justifyContent: 'center',
        alignItems: 'center',
        fontFamily: 'system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
      }}
    >
      <div
        style={{
          opacity: headerSpring,
          transform: `translateY(${interpolate(headerSpring, [0, 1], [-20, 0])}px)`,
          textAlign: 'center',
          marginBottom: 40,
        }}
      >
        <div style={{ color: '#FBBF24', fontSize: 22, fontWeight: 700, letterSpacing: 2, textTransform: 'uppercase', marginBottom: 8 }}>
          INGENIERÍA Y ARQUITECTURA ESCOLAR
        </div>
        <div style={{ color: '#FFFFFF', fontSize: 56, fontWeight: 800 }}>
          Los 6 Escenarios Oficiales a Escala Real
        </div>
        <div style={{ color: '#B7E4C7', fontSize: 22, marginTop: 8 }}>
          Modelados a razón de <span style={{ color: '#FFFFFF', fontWeight: 700 }}>1 metro = 40 píxeles</span> con datos topográficos del CEMSaD 22.
        </div>
      </div>

      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(3, 1fr)',
          gap: 24,
          width: '100%',
          maxWidth: 1350,
        }}
      >
        {buildings.map((b, idx) => {
          const itemSpring = spring({ frame, fps, delay: 12 + idx * 6, config: { damping: 15 } });

          return (
            <div
              key={b.id}
              style={{
                opacity: itemSpring,
                transform: `scale(${interpolate(itemSpring, [0, 1], [0.9, 1])})`,
                backgroundColor: 'rgba(16, 42, 28, 0.8)',
                border: '1.5px solid rgba(82, 183, 136, 0.35)',
                borderRadius: 20,
                padding: '24px 26px',
                display: 'flex',
                alignItems: 'center',
                gap: 20,
                boxShadow: '0 12px 24px rgba(0,0,0,0.25)',
              }}
            >
              <div
                style={{
                  width: 56,
                  height: 56,
                  borderRadius: 16,
                  backgroundColor: '#2D6A4F',
                  display: 'flex',
                  justifyContent: 'center',
                  alignItems: 'center',
                  fontSize: 26,
                  fontWeight: 900,
                  color: '#FBBF24',
                  boxShadow: '0 4px 12px rgba(0,0,0,0.3)',
                }}
              >
                {b.id}
              </div>
              <div style={{ flex: 1 }}>
                <div style={{ color: '#74C69D', fontSize: 14, fontWeight: 700, textTransform: 'uppercase' }}>
                  {b.type} · {b.area}
                </div>
                <div style={{ color: '#FFFFFF', fontSize: 22, fontWeight: 700, marginTop: 2 }}>
                  {b.name}
                </div>
              </div>
            </div>
          );
        })}
      </div>

      <div
        style={{
          marginTop: 36,
          backgroundColor: 'rgba(245, 158, 11, 0.15)',
          border: '1px solid rgba(245, 158, 11, 0.5)',
          borderRadius: 24,
          padding: '12px 32px',
          color: '#FDE68A',
          fontSize: 20,
          fontWeight: 600,
        }}
      >
        📐 Incluye visor interactivo CAD 2D (planos_interactivos.html) y maqueta BIM 3D Three.js (plano_3d.html)
      </div>
    </AbsoluteFill>
  );
};
"""

files['/src/scenes/MobileScene.tsx'] = """import React from 'react';
import { AbsoluteFill, useCurrentFrame, useVideoConfig, spring, interpolate } from 'remotion';

export const MobileScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const headerSpring = spring({ frame, fps, delay: 5, config: { damping: 15 } });
  const phoneSpring = spring({ frame, fps, delay: 16, config: { damping: 13, stiffness: 110 } });

  const joystickAngle = Math.sin(frame * 0.1) * 16;
  const pulseButton = 1 + Math.sin(frame * 0.15) * 0.06;

  return (
    <AbsoluteFill
      style={{
        padding: '60px 100px',
        justifyContent: 'center',
        alignItems: 'center',
        fontFamily: 'system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
      }}
    >
      <div
        style={{
          opacity: headerSpring,
          transform: `translateY(${interpolate(headerSpring, [0, 1], [-20, 0])}px)`,
          textAlign: 'center',
          marginBottom: 36,
        }}
      >
        <div style={{ color: '#10B981', fontSize: 22, fontWeight: 700, letterSpacing: 2, textTransform: 'uppercase', marginBottom: 8 }}>
          NOVEDAD OFICIAL DE LA VERSIÓN MÓVIL
        </div>
        <div style={{ color: '#FFFFFF', fontSize: 56, fontWeight: 800 }}>
          📱 Joysticks y Controles Táctiles Integrados
        </div>
        <div style={{ color: '#B7E4C7', fontSize: 24, marginTop: 8 }}>
          Diseñados a medida para pantallas táctiles en Android APK y navegadores móviles.
        </div>
      </div>

      <div
        style={{
          opacity: phoneSpring,
          transform: `scale(${interpolate(phoneSpring, [0, 1], [0.85, 1])})`,
          width: 960,
          height: 480,
          backgroundColor: '#0A1E13',
          border: '4px solid #2D6A4F',
          borderRadius: 36,
          boxShadow: '0 25px 60px rgba(0,0,0,0.6), 0 0 40px rgba(46, 125, 50, 0.3)',
          position: 'relative',
          overflow: 'hidden',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'flex-end',
          padding: '40px 60px',
        }}
      >
        <div
          style={{
            position: 'absolute',
            top: 24,
            left: '50%',
            transform: 'translateX(-50%)',
            backgroundColor: 'rgba(0,0,0,0.6)',
            padding: '8px 24px',
            borderRadius: 20,
            color: '#FFFFFF',
            fontSize: 18,
            fontWeight: 700,
            border: '1px solid rgba(255,255,255,0.2)',
          }}
        >
          ❤️ ❤️ ❤️  ·  Nivel 1: Acceso CEMSaD 22
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 14 }}>
          <div
            style={{
              width: 140,
              height: 140,
              borderRadius: '50%',
              backgroundColor: 'rgba(6, 20, 12, 0.65)',
              border: '3px solid #52B788',
              display: 'flex',
              justifyContent: 'center',
              alignItems: 'center',
              boxShadow: '0 0 25px rgba(82, 183, 136, 0.4)',
              position: 'relative',
            }}
          >
            <div
              style={{
                width: 64,
                height: 64,
                borderRadius: '50%',
                backgroundColor: '#2D6A4F',
                border: '3px solid #FFFFFF',
                boxShadow: '0 4px 15px rgba(0,0,0,0.5)',
                transform: `translate(${joystickAngle}px, ${-joystickAngle * 0.7}px)`,
              }}
            />
          </div>
          <div style={{ color: '#52B788', fontSize: 18, fontWeight: 700 }}>
            🕹️ Joystick 8 Direcciones
          </div>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 14 }}>
          <div
            style={{
              width: 120,
              height: 120,
              borderRadius: '50%',
              backgroundColor: '#D97706',
              border: '4px solid #FDE68A',
              display: 'flex',
              justifyContent: 'center',
              alignItems: 'center',
              color: '#FFFFFF',
              fontSize: 22,
              fontWeight: 900,
              letterSpacing: 1,
              transform: `scale(${pulseButton})`,
              boxShadow: '0 0 30px rgba(245, 158, 11, 0.6)',
            }}
          >
            VIRTUD
          </div>
          <div style={{ color: '#FBBF24', fontSize: 18, fontWeight: 700 }}>
            ✨ Botón de Disparo
          </div>
        </div>
      </div>
    </AbsoluteFill>
  );
};
"""

files['/src/scenes/ReleaseScene.tsx'] = """import React from 'react';
import { AbsoluteFill, useCurrentFrame, useVideoConfig, spring, interpolate } from 'remotion';

export const ReleaseScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const titleSpring = spring({ frame, fps, delay: 5, config: { damping: 15 } });

  const downloads = [
    { os: 'Android', file: 'campeones_valores.apk', size: '22.6 MB', icon: '📱', color: '#10B981' },
    { os: 'Linux', file: 'campeones_valores_linux_x86_64.zip', size: '23.6 MB', icon: '🐧', color: '#3B82F6' },
    { os: 'Windows', file: 'campeones_valores_windows_x86_64.zip', size: '29.4 MB', icon: '🪟', color: '#F59E0B' },
  ];

  return (
    <AbsoluteFill
      style={{
        padding: '70px 100px',
        justifyContent: 'center',
        alignItems: 'center',
        fontFamily: 'system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
      }}
    >
      <div
        style={{
          opacity: titleSpring,
          backgroundColor: '#059669',
          color: '#FFFFFF',
          padding: '6px 20px',
          borderRadius: 20,
          fontSize: 20,
          fontWeight: 800,
          letterSpacing: 2,
          marginBottom: 16,
        }}
      >
        LANZAMIENTO OFICIAL v1.0 DISPONIBLE
      </div>
      <div
        style={{
          opacity: titleSpring,
          transform: `scale(${interpolate(titleSpring, [0, 1], [0.85, 1])})`,
          textAlign: 'center',
          fontSize: 68,
          fontWeight: 900,
          color: '#FFFFFF',
          marginBottom: 16,
        }}
      >
        ¡Descarga y Juega Ahora Mismo!
      </div>
      <div
        style={{
          color: '#D8F3DC',
          fontSize: 24,
          textAlign: 'center',
          maxWidth: 900,
          marginBottom: 44,
        }}
      >
        Compilado y verificado automáticamente mediante <span style={{ color: '#FBBF24', fontWeight: 700 }}>GitHub Actions CI/CD</span>.
      </div>

      <div style={{ display: 'flex', gap: 32, width: '100%', maxWidth: 1300, justifyContent: 'center' }}>
        {downloads.map((d, i) => {
          const itemSpring = spring({ frame, fps, delay: 15 + i * 10, config: { damping: 14 } });
          return (
            <div
              key={d.os}
              style={{
                flex: 1,
                opacity: itemSpring,
                transform: `translateY(${interpolate(itemSpring, [0, 1], [30, 0])}px)`,
                backgroundColor: 'rgba(16, 42, 28, 0.85)',
                border: `2px solid ${d.color}`,
                borderRadius: 24,
                padding: '36px 28px',
                textAlign: 'center',
                boxShadow: '0 20px 40px rgba(0,0,0,0.3)',
              }}
            >
              <div style={{ fontSize: 50, marginBottom: 12 }}>{d.icon}</div>
              <div style={{ color: '#FFFFFF', fontSize: 28, fontWeight: 800 }}>{d.os}</div>
              <div style={{ color: '#74C69D', fontSize: 16, fontFamily: 'monospace', marginTop: 8, wordBreak: 'break-all' }}>
                {d.file}
              </div>
              <div style={{ color: d.color, fontSize: 18, fontWeight: 700, marginTop: 12 }}>
                Tamaño: {d.size}
              </div>
            </div>
          );
        })}
      </div>

      <div
        style={{
          marginTop: 44,
          fontSize: 22,
          color: '#FFFFFF',
          backgroundColor: 'rgba(255, 255, 255, 0.1)',
          border: '1px solid rgba(255, 255, 255, 0.25)',
          borderRadius: 30,
          padding: '12px 36px',
        }}
      >
        ⭐ Repositorio Oficial: <span style={{ color: '#FBBF24', fontWeight: 700 }}>github.com/Kineyo/valores-cobaem22</span>
      </div>
    </AbsoluteFill>
  );
};
"""

files['/src/Video.tsx'] = """import React from 'react';
import { AbsoluteFill } from 'remotion';
import { TransitionSeries, linearTiming } from '@remotion/transitions';
import { fade } from '@remotion/transitions/fade';
import { slide } from '@remotion/transitions/slide';
import { Background } from './components/Background';
import { IntroScene } from './scenes/IntroScene';
import { ValuesScene } from './scenes/ValuesScene';
import { ScenariosScene } from './scenes/ScenariosScene';
import { MobileScene } from './scenes/MobileScene';
import { ReleaseScene } from './scenes/ReleaseScene';

export default function Video() {
  return (
    <AbsoluteFill style={{ backgroundColor: '#07160E' }}>
      <Background />
      <TransitionSeries>
        <TransitionSeries.Sequence durationInFrames={110}>
          <IntroScene />
        </TransitionSeries.Sequence>
        <TransitionSeries.Transition
          presentation={fade()}
          timing={linearTiming({ durationInFrames: 15 })}
        />

        <TransitionSeries.Sequence durationInFrames={120}>
          <ValuesScene />
        </TransitionSeries.Sequence>
        <TransitionSeries.Transition
          presentation={slide({ direction: 'from-right' })}
          timing={linearTiming({ durationInFrames: 15 })}
        />

        <TransitionSeries.Sequence durationInFrames={120}>
          <ScenariosScene />
        </TransitionSeries.Sequence>
        <TransitionSeries.Transition
          presentation={slide({ direction: 'from-left' })}
          timing={linearTiming({ durationInFrames: 15 })}
        />

        <TransitionSeries.Sequence durationInFrames={110}>
          <MobileScene />
        </TransitionSeries.Sequence>
        <TransitionSeries.Transition
          presentation={fade()}
          timing={linearTiming({ durationInFrames: 15 })}
        />

        <TransitionSeries.Sequence durationInFrames={100}>
          <ReleaseScene />
        </TransitionSeries.Sequence>
      </TransitionSeries>
    </AbsoluteFill>
  );
}
"""

print('Enviando código fuente del video al servidor Remotion MCP...')
req = urllib.request.Request(
    'https://still-feather-l5mwy.run.mcp-use.com/mcp',
    data=json.dumps({
        'jsonrpc': '2.0',
        'id': 100,
        'method': 'tools/call',
        'params': {
            'name': 'create_video',
            'arguments': {
                'files': json.dumps(files),
                'title': 'Campeones de los Valores — Presentación del Repositorio y README',
                'durationInFrames': 500,
                'fps': 30,
                'width': 1920,
                'height': 1080,
            },
        },
    }).encode(),
    headers={'Content-Type': 'application/json'},
)

with urllib.request.urlopen(req) as resp:
  res = json.loads(resp.read().decode())
  print('Estado HTTP:', resp.status)
  if 'result' in res:
    for c in res['result'].get('content', []):
      print('Mensaje del servidor:', c.get('text', ''))

    video_proj_raw = res['result'].get('structuredContent', {}).get(
        'videoProject'
    )
    if video_proj_raw:
      # Generar HTML autocontenido
      html_content = f"""<!doctype html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Video: Campeones de los Valores — Presentación del Repositorio</title>
  <script>
    window.openai = {{
      toolOutput: {{
        videoProject: {json.dumps(video_proj_raw)}
      }}
    }};
    window.__getFile = (filename) => "https://still-feather-l5mwy.run.mcp-use.com/mcp-use/widgets/remotion-player/" + filename;
    window.__mcpPublicUrl = "https://still-feather-l5mwy.run.mcp-use.com/mcp-use/public";
  </script>
  <base href="https://still-feather-l5mwy.run.mcp-use.com" />
  <script type="module" crossorigin src="https://still-feather-l5mwy.run.mcp-use.com/mcp-use/widgets/remotion-player/assets/index-DW3vouaR.js"></script>
  <link rel="stylesheet" crossorigin href="https://still-feather-l5mwy.run.mcp-use.com/mcp-use/widgets/remotion-player/assets/index-DPnU1Iba.css">
  <style>
    body {{
      margin: 0;
      padding: 30px 20px;
      background: #06140B;
      color: #FFFFFF;
      font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      display: flex;
      flex-direction: column;
      align-items: center;
      min-height: 100vh;
      box-sizing: border-box;
    }}
    .header {{
      text-align: center;
      margin-bottom: 24px;
      max-width: 1100px;
    }}
    .badge {{
      display: inline-block;
      background: rgba(46, 125, 50, 0.35);
      border: 1px solid #52B788;
      border-radius: 20px;
      padding: 6px 18px;
      color: #74C69D;
      font-size: 14px;
      font-weight: 700;
      letter-spacing: 1px;
      margin-bottom: 12px;
    }}
    .header h1 {{
      margin: 0 0 10px 0;
      font-size: 34px;
      font-weight: 900;
      background: linear-gradient(135deg, #FFFFFF, #74C69D, #FBBF24);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
    }}
    .header p {{
      margin: 0;
      color: #D8F3DC;
      font-size: 16px;
      line-height: 1.5;
    }}
    .player-container {{
      width: 100%;
      max-width: 1100px;
      aspect-ratio: 16 / 9;
      box-shadow: 0 25px 60px rgba(0,0,0,0.7), 0 0 40px rgba(46, 125, 50, 0.25);
      border-radius: 16px;
      overflow: hidden;
      border: 2px solid rgba(82, 183, 136, 0.4);
      background: #000;
      position: relative;
    }}
    #widget-root {{
      width: 100%;
      height: 100%;
    }}
    .guide {{
      margin-top: 32px;
      max-width: 1100px;
      width: 100%;
      background: rgba(16, 42, 28, 0.7);
      border: 1px solid rgba(82, 183, 136, 0.35);
      border-radius: 16px;
      padding: 24px 32px;
      box-sizing: border-box;
      box-shadow: 0 15px 30px rgba(0,0,0,0.3);
    }}
    .guide h2 {{
      margin-top: 0;
      font-size: 20px;
      color: #FBBF24;
      display: flex;
      align-items: center;
      gap: 10px;
    }}
    .scene-grid {{
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
      gap: 16px;
      margin-top: 16px;
    }}
    .scene-card {{
      background: rgba(6, 20, 12, 0.6);
      border: 1px solid rgba(255, 255, 255, 0.1);
      border-radius: 12px;
      padding: 14px 18px;
    }}
    .scene-num {{
      font-size: 12px;
      font-weight: 700;
      color: #52B788;
      text-transform: uppercase;
      letter-spacing: 1px;
    }}
    .scene-title {{
      font-size: 16px;
      font-weight: 700;
      color: #FFF;
      margin: 4px 0 6px 0;
    }}
    .scene-desc {{
      font-size: 13px;
      color: #B7E4C7;
      line-height: 1.4;
      margin: 0;
    }}
    .footer {{
      margin-top: 30px;
      font-size: 14px;
      color: rgba(255,255,255,0.6);
      text-align: center;
    }}
    .footer a {{
      color: #FBBF24;
      text-decoration: none;
      font-weight: 600;
    }}
  </style>
</head>
<body>
  <div class="header">
    <div class="badge">🎬 VIDEO OFICIAL · REMOTION MCP</div>
    <h1>Campeones de los Valores</h1>
    <p>Presentación audiovisual generada a partir del <strong>README.md</strong> y especificaciones de la versión v1.0 con joysticks móviles.</p>
  </div>

  <div class="player-container">
    <div id="widget-root"></div>
  </div>

  <div class="guide">
    <h2>📑 Contenido y Escenas del Video (16.7s · 500 frames · 30 FPS)</h2>
    <div class="scene-grid">
      <div class="scene-card">
        <div class="scene-num">Escena 1 (0:00 - 0:03)</div>
        <div class="scene-title">🎮 Identidad Institucional</div>
        <p class="scene-desc">COBAEM CEMSaD 22 ENTHAVI, motor Godot 4.7, escala 1m = 40px y perspectiva 3/4.</p>
      </div>
      <div class="scene-card">
        <div class="scene-num">Escena 2 (0:03 - 0:07)</div>
        <div class="scene-title">💖 Cultura de Paz y Diálogo</div>
        <p class="scene-desc">Filosofía de no violencia: los antivalores (Acoso, Bullying, Grosería) son redimidos pacíficamente.</p>
      </div>
      <div class="scene-card">
        <div class="scene-num">Escena 3 (0:07 - 0:11)</div>
        <div class="scene-title">📐 Los 6 Escenarios Reales</div>
        <p class="scene-desc">Cafetería, Plaza Cívica (+4m), Biblioteca, Cómputo y Canchas con cotas métricas y visor CAD/3D.</p>
      </div>
      <div class="scene-card">
        <div class="scene-num">Escena 4 (0:11 - 0:14)</div>
        <div class="scene-title">📱 Joysticks para Móvil</div>
        <p class="scene-desc">Controles táctiles virtuales optimizados para pantallas táctiles en Android APK.</p>
      </div>
      <div class="scene-card">
        <div class="scene-num">Escena 5 (0:14 - 0:17)</div>
        <div class="scene-title">🚀 Lanzamiento Oficial v1.0</div>
        <p class="scene-desc">Descarga directa para Android APK, Linux x86_64 y Windows .exe en GitHub Releases.</p>
      </div>
    </div>
  </div>

  <div class="footer">
    Proyecto disponible en <a href="https://github.com/Kineyo/valores-cobaem22" target="_blank">github.com/Kineyo/valores-cobaem22</a> · Colegio de Bachilleres del Estado de México
  </div>
</body>
</html>
"""
      output_html = 'video_presentacion.html'
      with open(output_html, 'w', encoding='utf-8') as f:
        f.write(html_content)
      print(f'¡Archivo HTML del video generado con éxito: {output_html}!')

  if 'error' in res:
    print('Error:', res['error'])
