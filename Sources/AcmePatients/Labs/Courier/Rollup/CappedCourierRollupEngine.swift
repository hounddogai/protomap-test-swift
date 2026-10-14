import AcmePlatform
import Foundation

extension Labs {
    /// One step of the capped courier rollup calculation.
    protocol CappedCourierRollupStep {
        func describe() -> String
        func adjust(_ item: CappedCourierRollup, value: Double) -> Double
    }

    final class MinimumCappedCourierRollupAdjuster: CappedCourierRollupStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedCourierRollup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CappedCourierRollupVisitMinutesOffsetAdjuster: CappedCourierRollupStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus visit minutes times \(weight)"
        }

        func adjust(_ item: CappedCourierRollup, value: Double) -> Double {
            return value + Double(item.visitMinutes) * weight
        }
    }

    final class FlaggedCappedCourierRollupAdjuster: CappedCourierRollupStep {
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

        func adjust(_ item: CappedCourierRollup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the capped courier rollup steps in order and keeps a trace of each.
    final class CappedCourierRollupEngine {
        var steps: [any CappedCourierRollupStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedCourierRollupStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CappedCourierRollup) -> Double {
            var current = item.effectiveExposure()
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

        func evaluateAll(_ items: [CappedCourierRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCappedCourierRollupEngine(_ flags: Kit.Flags.Registry) -> CappedCourierRollupEngine {
        return CappedCourierRollupEngine(
            steps: [
                MinimumCappedCourierRollupAdjuster(minimum: 2.1),
                CappedCourierRollupVisitMinutesOffsetAdjuster(weight: 1.95),
                FlaggedCappedCourierRollupAdjuster(flags: flags, flag: "capped-courier-rollup-capped", percent: -3.2),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 26132.1
        )
    }
}
