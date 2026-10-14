import AcmePlatform
import Foundation

extension Labs {
    /// One step of the weighted accession mapping calculation.
    protocol WeightedAccessionMappingAdjuster {
        func describe() -> String
        func adjust(_ item: WeightedAccessionMapping, value: Double) -> Double
    }

    final class FlaggedWeightedAccessionMappingAdjuster: WeightedAccessionMappingAdjuster {
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

        func adjust(_ item: WeightedAccessionMapping, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingWeightedAccessionMappingAdjuster: WeightedAccessionMappingAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedAccessionMapping, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class RegionWeightedAccessionMappingAdjuster: WeightedAccessionMappingAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: WeightedAccessionMapping, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredWeightedAccessionMappingAdjuster: WeightedAccessionMappingAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedAccessionMapping, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumWeightedAccessionMappingAdjuster: WeightedAccessionMappingAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedAccessionMapping, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the weighted accession mapping steps in order and keeps a trace of each.
    final class WeightedAccessionMappingEngine {
        var steps: [any WeightedAccessionMappingAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedAccessionMappingAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: WeightedAccessionMapping) -> Double {
            var current = item.weightedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any WeightedAccessionMappingAdjuster = steps[index]
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

        func evaluateAll(_ items: [WeightedAccessionMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultWeightedAccessionMappingEngine(_ flags: Kit.Flags.Registry) -> WeightedAccessionMappingEngine {
        return WeightedAccessionMappingEngine(
            steps: [
                FlaggedWeightedAccessionMappingAdjuster(
                    flags: flags,
                    flag: "weighted-accession-mapping-lenient",
                    percent: 7.2
                ),
                RoundingWeightedAccessionMappingAdjuster(step: 1.0),
                RegionWeightedAccessionMappingAdjuster(factors: ["north": 0.81, "online": 1.13, "west": 0.89]),
                TieredWeightedAccessionMappingAdjuster(bounds: [3197.0, 3643.0], rates: [1.04, 1.11]),
                MinimumWeightedAccessionMappingAdjuster(minimum: 14.1),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 54198.5
        )
    }
}
