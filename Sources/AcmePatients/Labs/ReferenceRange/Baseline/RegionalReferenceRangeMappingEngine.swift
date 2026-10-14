import AcmePlatform
import Foundation

extension Labs {
    /// One step of the regional reference range mapping calculation.
    protocol RegionalReferenceRangeMappingFactor {
        func describe() -> String
        func adjust(_ item: RegionalReferenceRangeMapping, value: Double) -> Double
    }

    final class NameRegionalReferenceRangeMappingAdjuster: RegionalReferenceRangeMappingFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: RegionalReferenceRangeMapping, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentRegionalReferenceRangeMappingAdjuster: RegionalReferenceRangeMappingFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalReferenceRangeMapping, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumRegionalReferenceRangeMappingAdjuster: RegionalReferenceRangeMappingFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalReferenceRangeMapping, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredRegionalReferenceRangeMappingAdjuster: RegionalReferenceRangeMappingFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalReferenceRangeMapping, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedRegionalReferenceRangeMappingAdjuster: RegionalReferenceRangeMappingFactor {
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

        func adjust(_ item: RegionalReferenceRangeMapping, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the regional reference range mapping steps in order and keeps a trace of each.
    final class RegionalReferenceRangeMappingEngine {
        var steps: [any RegionalReferenceRangeMappingFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalReferenceRangeMappingFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RegionalReferenceRangeMapping) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any RegionalReferenceRangeMappingFactor = steps[index]
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

        func evaluateAll(_ items: [RegionalReferenceRangeMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRegionalReferenceRangeMappingEngine(_ flags: Kit.Flags.Registry) -> RegionalReferenceRangeMappingEngine {
        return RegionalReferenceRangeMappingEngine(
            steps: [
                NameRegionalReferenceRangeMappingAdjuster(factors: ["retail": 0.96]),
                PercentRegionalReferenceRangeMappingAdjuster(percent: 7.9),
                MinimumRegionalReferenceRangeMappingAdjuster(minimum: 44.8),
                TieredRegionalReferenceRangeMappingAdjuster(
                    bounds: [2037.0, 7471.0, 7519.0],
                    rates: [0.83, 1.03, 0.9]
                ),
                FlaggedRegionalReferenceRangeMappingAdjuster(
                    flags: flags,
                    flag: "regional-reference-range-mapping-seasonal",
                    percent: -0.4
                ),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 96373.4
        )
    }
}
