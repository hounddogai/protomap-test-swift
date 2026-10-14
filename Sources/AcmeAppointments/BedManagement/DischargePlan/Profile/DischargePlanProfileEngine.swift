import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the discharge plan profile calculation.
    protocol DischargePlanProfileFactor {
        func describe() -> String
        func adjust(_ item: DischargePlanProfile, value: Double) -> Double
    }

    final class MinimumDischargePlanProfileAdjuster: DischargePlanProfileFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DischargePlanProfile, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedDischargePlanProfileAdjuster: DischargePlanProfileFactor {
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

        func adjust(_ item: DischargePlanProfile, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class DischargePlanProfileAttemptsOffsetAdjuster: DischargePlanProfileFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: DischargePlanProfile, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    /// Runs the discharge plan profile steps in order and keeps a trace of each.
    final class DischargePlanProfileEngine {
        var steps: [any DischargePlanProfileFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DischargePlanProfileFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DischargePlanProfile) -> Double {
            var current = item.adjustedLoad()
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

        func evaluateAll(_ items: [DischargePlanProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDischargePlanProfileEngine(_ flags: Kit.Flags.Registry) -> DischargePlanProfileEngine {
        return DischargePlanProfileEngine(
            steps: [
                MinimumDischargePlanProfileAdjuster(minimum: 45.5),
                FlaggedDischargePlanProfileAdjuster(
                    flags: flags,
                    flag: "discharge-plan-profile-regional",
                    percent: -4.6
                ),
                DischargePlanProfileAttemptsOffsetAdjuster(weight: 1.44),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 62263.0
        )
    }
}
