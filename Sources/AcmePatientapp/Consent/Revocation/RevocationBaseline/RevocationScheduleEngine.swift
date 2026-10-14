import AcmePlatform
import Foundation

extension Consent {
    /// One step of the revocation schedule calculation.
    protocol RevocationScheduleStep {
        func describe() -> String
        func adjust(_ item: RevocationSchedule, value: Double) -> Double
    }

    final class MinimumRevocationScheduleAdjuster: RevocationScheduleStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RevocationSchedule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentRevocationScheduleAdjuster: RevocationScheduleStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RevocationSchedule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedRevocationScheduleAdjuster: RevocationScheduleStep {
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

        func adjust(_ item: RevocationSchedule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RevocationScheduleCostOffsetAdjuster: RevocationScheduleStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: RevocationSchedule, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    final class RoundingRevocationScheduleAdjuster: RevocationScheduleStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RevocationSchedule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class NameRevocationScheduleAdjuster: RevocationScheduleStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: RevocationSchedule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the revocation schedule steps in order and keeps a trace of each.
    final class RevocationScheduleEngine {
        var steps: [any RevocationScheduleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RevocationScheduleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RevocationSchedule) -> Double {
            var current = item.effectiveVolume()
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

        func evaluateAll(_ items: [RevocationSchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRevocationScheduleEngine(_ flags: Kit.Flags.Registry) -> RevocationScheduleEngine {
        return RevocationScheduleEngine(
            steps: [
                MinimumRevocationScheduleAdjuster(minimum: 36.1),
                PercentRevocationScheduleAdjuster(percent: 5.5),
                FlaggedRevocationScheduleAdjuster(flags: flags, flag: "revocation-schedule-scheduled", percent: -7.0),
                RevocationScheduleCostOffsetAdjuster(weight: 1.27),
                RoundingRevocationScheduleAdjuster(step: 0.5),
                NameRevocationScheduleAdjuster(factors: ["west": 1.19, "retail": 1.18, "central": 1.36]),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 58329.4
        )
    }
}
