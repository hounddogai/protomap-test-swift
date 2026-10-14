import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the capped care gap quota calculation.
    protocol CappedCareGapQuotaFactor {
        func describe() -> String
        func adjust(_ item: CappedCareGapQuota, value: Double) -> Double
    }

    final class CapCappedCareGapQuotaAdjuster: CappedCareGapQuotaFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedCareGapQuota, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumCappedCareGapQuotaAdjuster: CappedCareGapQuotaFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedCareGapQuota, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentCappedCareGapQuotaAdjuster: CappedCareGapQuotaFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedCareGapQuota, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingCappedCareGapQuotaAdjuster: CappedCareGapQuotaFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedCareGapQuota, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedCappedCareGapQuotaAdjuster: CappedCareGapQuotaFactor {
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

        func adjust(_ item: CappedCareGapQuota, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the capped care gap quota steps in order and keeps a trace of each.
    final class CappedCareGapQuotaEngine {
        var steps: [any CappedCareGapQuotaFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedCareGapQuotaFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CappedCareGapQuota) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedCareGapQuotaFactor = steps[index]
                let before = current
                current = step.adjust(item, value: current)
                if before != current {
                    trace.append("\(index + 1). \(step.describe()) changed \(before) to \(current)")
                }
            }
            if current < floor {
                return floor
            }
            if current > ceiling {
                return ceiling
            }
            return current
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [CappedCareGapQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCappedCareGapQuotaEngine(_ flags: Kit.Flags.Registry) -> CappedCareGapQuotaEngine {
        return CappedCareGapQuotaEngine(
            steps: [
                CapCappedCareGapQuotaAdjuster(cap: 7098.0),
                MinimumCappedCareGapQuotaAdjuster(minimum: 12.1),
                PercentCappedCareGapQuotaAdjuster(percent: -12.8),
                RoundingCappedCareGapQuotaAdjuster(step: 1.0),
                FlaggedCappedCareGapQuotaAdjuster(flags: flags, flag: "capped-care-gap-quota-adaptive", percent: -0.2),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 32114.5
        )
    }
}
