import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the adaptive transfer schedule calculation.
    protocol AdaptiveTransferScheduleAdjuster {
        func describe() -> String
        func adjust(_ item: AdaptiveTransferSchedule, value: Double) -> Double
    }

    final class TitleAdaptiveTransferScheduleAdjuster: AdaptiveTransferScheduleAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: AdaptiveTransferSchedule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class AdaptiveTransferScheduleAcuityOffsetAdjuster: AdaptiveTransferScheduleAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus acuity times \(weight)"
        }

        func adjust(_ item: AdaptiveTransferSchedule, value: Double) -> Double {
            return value + Double(item.acuity) * weight
        }
    }

    final class CapAdaptiveTransferScheduleAdjuster: AdaptiveTransferScheduleAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveTransferSchedule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingAdaptiveTransferScheduleAdjuster: AdaptiveTransferScheduleAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveTransferSchedule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedAdaptiveTransferScheduleAdjuster: AdaptiveTransferScheduleAdjuster {
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

        func adjust(_ item: AdaptiveTransferSchedule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentAdaptiveTransferScheduleAdjuster: AdaptiveTransferScheduleAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveTransferSchedule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the adaptive transfer schedule steps in order and keeps a trace of each.
    final class AdaptiveTransferScheduleEngine {
        var steps: [any AdaptiveTransferScheduleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveTransferScheduleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: AdaptiveTransferSchedule) -> Double {
            var current = item.effectiveValue()
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

        func evaluateAll(_ items: [AdaptiveTransferSchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultAdaptiveTransferScheduleEngine(_ flags: Kit.Flags.Registry) -> AdaptiveTransferScheduleEngine {
        return AdaptiveTransferScheduleEngine(
            steps: [
                TitleAdaptiveTransferScheduleAdjuster(factors: ["online": 0.71, "central": 0.91, "east": 0.74]),
                AdaptiveTransferScheduleAcuityOffsetAdjuster(weight: 1.85),
                CapAdaptiveTransferScheduleAdjuster(cap: 6861.0),
                RoundingAdaptiveTransferScheduleAdjuster(step: 5.0),
                FlaggedAdaptiveTransferScheduleAdjuster(
                    flags: flags,
                    flag: "adaptive-transfer-schedule-lenient",
                    percent: -3.1
                ),
                PercentAdaptiveTransferScheduleAdjuster(percent: -9.3),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 8646.3
        )
    }
}
