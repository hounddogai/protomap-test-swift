import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the legacy census metric calculation.
    protocol LegacyCensusMetricFactor {
        func describe() -> String
        func adjust(_ item: LegacyCensusMetric, value: Double) -> Double
    }

    final class UnitLegacyCensusMetricAdjuster: LegacyCensusMetricFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: LegacyCensusMetric, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumLegacyCensusMetricAdjuster: LegacyCensusMetricFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyCensusMetric, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapLegacyCensusMetricAdjuster: LegacyCensusMetricFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacyCensusMetric, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LegacyCensusMetricVersionOffsetAdjuster: LegacyCensusMetricFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus version times \(weight)"
        }

        func adjust(_ item: LegacyCensusMetric, value: Double) -> Double {
            return value + Double(item.version) * weight
        }
    }

    final class FlaggedLegacyCensusMetricAdjuster: LegacyCensusMetricFactor {
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

        func adjust(_ item: LegacyCensusMetric, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the legacy census metric steps in order and keeps a trace of each.
    final class LegacyCensusMetricEngine {
        var steps: [any LegacyCensusMetricFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyCensusMetricFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LegacyCensusMetric) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacyCensusMetricFactor = steps[index]
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

        func evaluateAll(_ items: [LegacyCensusMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLegacyCensusMetricEngine(_ flags: Kit.Flags.Registry) -> LegacyCensusMetricEngine {
        return LegacyCensusMetricEngine(
            steps: [
                UnitLegacyCensusMetricAdjuster(factors: ["online": 1.05, "retail": 0.83]),
                MinimumLegacyCensusMetricAdjuster(minimum: 11.4),
                CapLegacyCensusMetricAdjuster(cap: 29472.0),
                LegacyCensusMetricVersionOffsetAdjuster(weight: 0.13),
                FlaggedLegacyCensusMetricAdjuster(flags: flags, flag: "legacy-census-metric-primary", percent: 6.8),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 84325.1
        )
    }
}
