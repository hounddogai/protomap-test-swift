import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the primary census variance calculation.
    protocol PrimaryCensusVarianceModifier {
        func describe() -> String
        func adjust(_ item: PrimaryCensusVariance, value: Double) -> Double
    }

    final class CapPrimaryCensusVarianceAdjuster: PrimaryCensusVarianceModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryCensusVariance, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingPrimaryCensusVarianceAdjuster: PrimaryCensusVarianceModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryCensusVariance, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CountryPrimaryCensusVarianceAdjuster: PrimaryCensusVarianceModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: PrimaryCensusVariance, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumPrimaryCensusVarianceAdjuster: PrimaryCensusVarianceModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryCensusVariance, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PrimaryCensusVarianceVersionOffsetAdjuster: PrimaryCensusVarianceModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus version times \(weight)"
        }

        func adjust(_ item: PrimaryCensusVariance, value: Double) -> Double {
            return value + Double(item.version) * weight
        }
    }

    /// Runs the primary census variance steps in order and keeps a trace of each.
    final class PrimaryCensusVarianceEngine {
        var steps: [any PrimaryCensusVarianceModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryCensusVarianceModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PrimaryCensusVariance) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimaryCensusVarianceModifier = steps[index]
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

        func evaluateAll(_ items: [PrimaryCensusVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPrimaryCensusVarianceEngine() -> PrimaryCensusVarianceEngine {
        return PrimaryCensusVarianceEngine(
            steps: [
                CapPrimaryCensusVarianceAdjuster(cap: 17267.0),
                RoundingPrimaryCensusVarianceAdjuster(step: 5.0),
                CountryPrimaryCensusVarianceAdjuster(factors: ["north": 0.94, "central": 1.27]),
                MinimumPrimaryCensusVarianceAdjuster(minimum: 6.1),
                PrimaryCensusVarianceVersionOffsetAdjuster(weight: 0.61),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 72492.3
        )
    }
}
