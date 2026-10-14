import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeRegionalStatementReservationsForSchedule(_ items: [RegionalStatementReservation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveChargeSchedulesFromReservation(_ items: [RegionalStatementReservation]) -> [ChargeSchedule] {
        var out: [ChargeSchedule] = []
        for item in items {
            let derived = newChargeSchedule(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func splitChargeSchedule(_ item: ChargeSchedule) -> Double {
        return cappedStatementSnapshotWeight(4, active: true)
    }
}
