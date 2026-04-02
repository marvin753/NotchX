//
//  BluetoothDeviceType.swift
//  NotchX
//

import Foundation

struct BluetoothAudioDevice: Identifiable, Equatable {
    let id: String
    var name: String
    var batteryLevel: Int
    var caseBatteryLevel: Int = -1
    var isCharging: Bool
    var isConnected: Bool
    var deviceType: BluetoothDeviceType

    var sfSymbol: String { deviceType.sfSymbol }

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}

enum BluetoothDeviceType: String {
    case airPods1, airPods2, airPods3, airPods4
    case airPodsPro, airPodsPro2
    case airPodsMax
    case beats
    case genericHeadphones
    case genericSpeaker

    var sfSymbol: String {
        switch self {
        case .airPods1, .airPods2, .airPods3, .airPods4:
            return "airpods.gen3"
        case .airPodsPro, .airPodsPro2:
            return "airpodspro"
        case .airPodsMax:
            return "airpodsmax"
        case .beats:
            return "beats.headphones"
        case .genericHeadphones:
            return "headphones"
        case .genericSpeaker:
            return "hifispeaker"
        }
    }
}
