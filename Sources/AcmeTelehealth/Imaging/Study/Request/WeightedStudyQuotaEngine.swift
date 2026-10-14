import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the weighted study quota calculation.
    protocol WeightedStudyQuotaFactor {
        func describe() -> String
        func adjust(_ item: WeightedStudyQuota, value: Double) -> Double
    }

    final class CapWeightedStudyQuotaAdjuster: WeightedStudyQuotaFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedStudyQuota, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingWeightedStudyQuotaAdjuster: WeightedStudyQuotaFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedStudyQuota, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedWeightedStudyQuotaAdjuster: WeightedStudyQuotaFactor {
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

        func adjust(_ item: WeightedStudyQuota, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the weighted study quota steps in order and keeps a trace of each.
    final class WeightedStudyQuotaEngine {
        var steps: [any WeightedStudyQuotaFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedStudyQuotaFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: WeightedStudyQuota) -> Double {
            var current = item.netValue()
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

        func evaluateAll(_ items: [WeightedStudyQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultWeightedStudyQuotaEngine(_ flags: Kit.Flags.Registry) -> WeightedStudyQuotaEngine {
        return WeightedStudyQuotaEngine(
            steps: [
                CapWeightedStudyQuotaAdjuster(cap: 25806.0),
                RoundingWeightedStudyQuotaAdjuster(step: 0.1),
                FlaggedWeightedStudyQuotaAdjuster(flags: flags, flag: "weighted-study-quota-fallback", percent: -9.9),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 29555.1
        )
    }
}
