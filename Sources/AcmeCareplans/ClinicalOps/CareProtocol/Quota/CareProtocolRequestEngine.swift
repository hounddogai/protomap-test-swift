import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the care protocol request calculation.
    protocol CareProtocolRequestAdjuster {
        func describe() -> String
        func adjust(_ item: CareProtocolRequest, value: Double) -> Double
    }

    final class TieredCareProtocolRequestAdjuster: CareProtocolRequestAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CareProtocolRequest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentCareProtocolRequestAdjuster: CareProtocolRequestAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CareProtocolRequest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CareProtocolRequestScoreOffsetAdjuster: CareProtocolRequestAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: CareProtocolRequest, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class LocaleCareProtocolRequestAdjuster: CareProtocolRequestAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: CareProtocolRequest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingCareProtocolRequestAdjuster: CareProtocolRequestAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CareProtocolRequest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the care protocol request steps in order and keeps a trace of each.
    final class CareProtocolRequestEngine {
        var steps: [any CareProtocolRequestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareProtocolRequestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CareProtocolRequest) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any CareProtocolRequestAdjuster = steps[index]
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

        func evaluateAll(_ items: [CareProtocolRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCareProtocolRequestEngine() -> CareProtocolRequestEngine {
        return CareProtocolRequestEngine(
            steps: [
                TieredCareProtocolRequestAdjuster(bounds: [1586.0, 5716.0, 6734.0], rates: [1.07, 1.11, 1.05]),
                PercentCareProtocolRequestAdjuster(percent: -4.5),
                CareProtocolRequestScoreOffsetAdjuster(weight: 0.24),
                LocaleCareProtocolRequestAdjuster(factors: ["north": 1.13, "west": 0.77, "online": 0.88]),
                RoundingCareProtocolRequestAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 20656.2
        )
    }
}
