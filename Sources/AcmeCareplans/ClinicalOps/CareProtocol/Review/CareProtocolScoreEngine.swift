import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the care protocol score calculation.
    protocol CareProtocolScoreStep {
        func describe() -> String
        func adjust(_ item: CareProtocolScore, value: Double) -> Double
    }

    final class FacilityCareProtocolScoreAdjuster: CareProtocolScoreStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: CareProtocolScore, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingCareProtocolScoreAdjuster: CareProtocolScoreStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CareProtocolScore, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredCareProtocolScoreAdjuster: CareProtocolScoreStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CareProtocolScore, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the care protocol score steps in order and keeps a trace of each.
    final class CareProtocolScoreEngine {
        var steps: [any CareProtocolScoreStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareProtocolScoreStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CareProtocolScore) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any CareProtocolScoreStep = steps[index]
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

        func evaluateAll(_ items: [CareProtocolScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCareProtocolScoreEngine() -> CareProtocolScoreEngine {
        return CareProtocolScoreEngine(
            steps: [
                FacilityCareProtocolScoreAdjuster(factors: ["east": 0.72]),
                RoundingCareProtocolScoreAdjuster(step: 0.1),
                TieredCareProtocolScoreAdjuster(bounds: [2577.0, 7812.0], rates: [1.14, 1.18]),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 8094.1
        )
    }
}
