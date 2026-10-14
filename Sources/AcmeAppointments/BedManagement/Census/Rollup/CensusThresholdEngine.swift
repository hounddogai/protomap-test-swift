import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the census threshold calculation.
    protocol CensusThresholdAdjuster {
        func describe() -> String
        func adjust(_ item: CensusThreshold, value: Double) -> Double
    }

    final class PercentCensusThresholdAdjuster: CensusThresholdAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CensusThreshold, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredCensusThresholdAdjuster: CensusThresholdAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CensusThreshold, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedCensusThresholdAdjuster: CensusThresholdAdjuster {
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

        func adjust(_ item: CensusThreshold, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CensusThresholdPriorityOffsetAdjuster: CensusThresholdAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus priority times \(weight)"
        }

        func adjust(_ item: CensusThreshold, value: Double) -> Double {
            return value + Double(item.priority) * weight
        }
    }

    final class TitleCensusThresholdAdjuster: CensusThresholdAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: CensusThreshold, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingCensusThresholdAdjuster: CensusThresholdAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CensusThreshold, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the census threshold steps in order and keeps a trace of each.
    final class CensusThresholdEngine {
        var steps: [any CensusThresholdAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CensusThresholdAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CensusThreshold) -> Double {
            var current = item.weightedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any CensusThresholdAdjuster = steps[index]
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

        func evaluateAll(_ items: [CensusThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCensusThresholdEngine(_ flags: Kit.Flags.Registry) -> CensusThresholdEngine {
        return CensusThresholdEngine(
            steps: [
                PercentCensusThresholdAdjuster(percent: 15.1),
                TieredCensusThresholdAdjuster(bounds: [4362.0, 6019.0], rates: [1.14, 0.88]),
                FlaggedCensusThresholdAdjuster(flags: flags, flag: "census-threshold-pending", percent: 9.0),
                CensusThresholdPriorityOffsetAdjuster(weight: 0.61),
                TitleCensusThresholdAdjuster(factors: ["west": 0.79, "central": 1.13]),
                RoundingCensusThresholdAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 64118.6
        )
    }
}
