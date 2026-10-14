import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the manual outreach slot calculation.
    protocol ManualOutreachSlotAdjuster {
        func describe() -> String
        func adjust(_ item: ManualOutreachSlot, value: Double) -> Double
    }

    final class FlaggedManualOutreachSlotAdjuster: ManualOutreachSlotAdjuster {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: ManualOutreachSlot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumManualOutreachSlotAdjuster: ManualOutreachSlotAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualOutreachSlot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredManualOutreachSlotAdjuster: ManualOutreachSlotAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualOutreachSlot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class WardManualOutreachSlotAdjuster: ManualOutreachSlotAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: ManualOutreachSlot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapManualOutreachSlotAdjuster: ManualOutreachSlotAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualOutreachSlot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentManualOutreachSlotAdjuster: ManualOutreachSlotAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualOutreachSlot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the manual outreach slot steps in order and keeps a trace of each.
    final class ManualOutreachSlotEngine {
        var steps: [any ManualOutreachSlotAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualOutreachSlotAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ManualOutreachSlot) -> Double {
            var current = item.netExposure()
            trace = []
            for step in steps {
                let next = step.adjust(item, value: current)
                trace.append("\(step.describe()): \((current * 100).rounded() / 100) -> \((next * 100).rounded() / 100)")
                current = next
            }
            return Kit.Numbers.clampFloat(current, low: floor, high: ceiling)
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [ManualOutreachSlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultManualOutreachSlotEngine(_ flags: Kit.Flags.Registry) -> ManualOutreachSlotEngine {
        return ManualOutreachSlotEngine(
            steps: [
                FlaggedManualOutreachSlotAdjuster(flags: flags, flag: "manual-outreach-slot-legacy", percent: 5.4),
                MinimumManualOutreachSlotAdjuster(minimum: 8.4),
                TieredManualOutreachSlotAdjuster(bounds: [8542.0, 9436.0], rates: [0.9, 0.81]),
                WardManualOutreachSlotAdjuster(factors: ["east": 1.05, "south": 1.23]),
                CapManualOutreachSlotAdjuster(cap: 21228.0),
                PercentManualOutreachSlotAdjuster(percent: 8.7),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 81082.4
        )
    }
}
