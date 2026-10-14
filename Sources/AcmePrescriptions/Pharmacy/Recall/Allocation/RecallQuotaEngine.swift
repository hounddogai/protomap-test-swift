import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the recall quota calculation.
    protocol RecallQuotaFactor {
        func describe() -> String
        func adjust(_ item: RecallQuota, value: Double) -> Double
    }

    final class RoundingRecallQuotaAdjuster: RecallQuotaFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RecallQuota, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedRecallQuotaAdjuster: RecallQuotaFactor {
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

        func adjust(_ item: RecallQuota, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapRecallQuotaAdjuster: RecallQuotaFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RecallQuota, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class CategoryRecallQuotaAdjuster: RecallQuotaFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: RecallQuota, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumRecallQuotaAdjuster: RecallQuotaFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RecallQuota, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the recall quota steps in order and keeps a trace of each.
    final class RecallQuotaEngine {
        var steps: [any RecallQuotaFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RecallQuotaFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RecallQuota) -> Double {
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

        func evaluateAll(_ items: [RecallQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRecallQuotaEngine(_ flags: Kit.Flags.Registry) -> RecallQuotaEngine {
        return RecallQuotaEngine(
            steps: [
                RoundingRecallQuotaAdjuster(step: 0.05),
                FlaggedRecallQuotaAdjuster(flags: flags, flag: "recall-quota-adaptive", percent: -9.0),
                CapRecallQuotaAdjuster(cap: 33793.0),
                CategoryRecallQuotaAdjuster(factors: ["retail": 0.97, "west": 0.79, "east": 1.37]),
                MinimumRecallQuotaAdjuster(minimum: 42.3),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 73398.6
        )
    }
}
