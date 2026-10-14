import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the regional handoff quota calculation.
    protocol RegionalHandoffQuotaAdjuster {
        func describe() -> String
        func adjust(_ item: RegionalHandoffQuota, value: Double) -> Double
    }

    final class CapRegionalHandoffQuotaAdjuster: RegionalHandoffQuotaAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalHandoffQuota, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentRegionalHandoffQuotaAdjuster: RegionalHandoffQuotaAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalHandoffQuota, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RegionalHandoffQuotaMinimumOffsetAdjuster: RegionalHandoffQuotaAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: RegionalHandoffQuota, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    final class RoundingRegionalHandoffQuotaAdjuster: RegionalHandoffQuotaAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalHandoffQuota, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedRegionalHandoffQuotaAdjuster: RegionalHandoffQuotaAdjuster {
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

        func adjust(_ item: RegionalHandoffQuota, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the regional handoff quota steps in order and keeps a trace of each.
    final class RegionalHandoffQuotaEngine {
        var steps: [any RegionalHandoffQuotaAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalHandoffQuotaAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RegionalHandoffQuota) -> Double {
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

        func evaluateAll(_ items: [RegionalHandoffQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRegionalHandoffQuotaEngine(_ flags: Kit.Flags.Registry) -> RegionalHandoffQuotaEngine {
        return RegionalHandoffQuotaEngine(
            steps: [
                CapRegionalHandoffQuotaAdjuster(cap: 12311.0),
                PercentRegionalHandoffQuotaAdjuster(percent: 16.2),
                RegionalHandoffQuotaMinimumOffsetAdjuster(weight: 0.77),
                RoundingRegionalHandoffQuotaAdjuster(step: 0.25),
                FlaggedRegionalHandoffQuotaAdjuster(flags: flags, flag: "regional-handoff-quota-tiered", percent: 1.0),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 60806.3
        )
    }
}
