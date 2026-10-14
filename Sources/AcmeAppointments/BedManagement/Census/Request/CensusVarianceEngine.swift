import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the census variance calculation.
    protocol CensusVarianceAdjuster {
        func describe() -> String
        func adjust(_ item: CensusVariance, value: Double) -> Double
    }

    final class CensusVarianceBatchSizeOffsetAdjuster: CensusVarianceAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: CensusVariance, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    final class FlaggedCensusVarianceAdjuster: CensusVarianceAdjuster {
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

        func adjust(_ item: CensusVariance, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingCensusVarianceAdjuster: CensusVarianceAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CensusVariance, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumCensusVarianceAdjuster: CensusVarianceAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CensusVariance, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class UnitCensusVarianceAdjuster: CensusVarianceAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: CensusVariance, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the census variance steps in order and keeps a trace of each.
    final class CensusVarianceEngine {
        var steps: [any CensusVarianceAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CensusVarianceAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CensusVariance) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any CensusVarianceAdjuster = steps[index]
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

        func evaluateAll(_ items: [CensusVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCensusVarianceEngine(_ flags: Kit.Flags.Registry) -> CensusVarianceEngine {
        return CensusVarianceEngine(
            steps: [
                CensusVarianceBatchSizeOffsetAdjuster(weight: 1.04),
                FlaggedCensusVarianceAdjuster(flags: flags, flag: "census-variance-global", percent: 3.9),
                RoundingCensusVarianceAdjuster(step: 0.25),
                MinimumCensusVarianceAdjuster(minimum: 5.7),
                UnitCensusVarianceAdjuster(factors: ["online": 0.95]),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 27230.9
        )
    }
}
