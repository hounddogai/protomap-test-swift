import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the regional float pool quota calculation.
    protocol RegionalFloatPoolQuotaModifier {
        func describe() -> String
        func adjust(_ item: RegionalFloatPoolQuota, value: Double) -> Double
    }

    final class RoundingRegionalFloatPoolQuotaAdjuster: RegionalFloatPoolQuotaModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalFloatPoolQuota, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TitleRegionalFloatPoolQuotaAdjuster: RegionalFloatPoolQuotaModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: RegionalFloatPoolQuota, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumRegionalFloatPoolQuotaAdjuster: RegionalFloatPoolQuotaModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalFloatPoolQuota, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedRegionalFloatPoolQuotaAdjuster: RegionalFloatPoolQuotaModifier {
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

        func adjust(_ item: RegionalFloatPoolQuota, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapRegionalFloatPoolQuotaAdjuster: RegionalFloatPoolQuotaModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalFloatPoolQuota, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the regional float pool quota steps in order and keeps a trace of each.
    final class RegionalFloatPoolQuotaEngine {
        var steps: [any RegionalFloatPoolQuotaModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalFloatPoolQuotaModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RegionalFloatPoolQuota) -> Double {
            var current = item.projectedValue()
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

        func evaluateAll(_ items: [RegionalFloatPoolQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRegionalFloatPoolQuotaEngine(_ flags: Kit.Flags.Registry) -> RegionalFloatPoolQuotaEngine {
        return RegionalFloatPoolQuotaEngine(
            steps: [
                RoundingRegionalFloatPoolQuotaAdjuster(step: 0.25),
                TitleRegionalFloatPoolQuotaAdjuster(factors: ["east": 1.1, "west": 0.76, "online": 1.04]),
                MinimumRegionalFloatPoolQuotaAdjuster(minimum: 5.3),
                FlaggedRegionalFloatPoolQuotaAdjuster(
                    flags: flags,
                    flag: "regional-float-pool-quota-batched",
                    percent: -5.0
                ),
                CapRegionalFloatPoolQuotaAdjuster(cap: 22199.0),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 43105.0
        )
    }
}
