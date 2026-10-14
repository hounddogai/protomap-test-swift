import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the adaptive handoff request calculation.
    protocol AdaptiveHandoffRequestFactor {
        func describe() -> String
        func adjust(_ item: AdaptiveHandoffRequest, value: Double) -> Double
    }

    final class ChannelAdaptiveHandoffRequestAdjuster: AdaptiveHandoffRequestFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: AdaptiveHandoffRequest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredAdaptiveHandoffRequestAdjuster: AdaptiveHandoffRequestFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveHandoffRequest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingAdaptiveHandoffRequestAdjuster: AdaptiveHandoffRequestFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveHandoffRequest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the adaptive handoff request steps in order and keeps a trace of each.
    final class AdaptiveHandoffRequestEngine {
        var steps: [any AdaptiveHandoffRequestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveHandoffRequestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AdaptiveHandoffRequest) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveHandoffRequestFactor = steps[index]
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

        func evaluateAll(_ items: [AdaptiveHandoffRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAdaptiveHandoffRequestEngine() -> AdaptiveHandoffRequestEngine {
        return AdaptiveHandoffRequestEngine(
            steps: [
                ChannelAdaptiveHandoffRequestAdjuster(factors: ["online": 1.02, "north": 1.13, "west": 0.94]),
                TieredAdaptiveHandoffRequestAdjuster(
                    bounds: [3038.0, 5259.0, 9876.0, 9979.0],
                    rates: [1.06, 0.94, 1.03, 1.08]
                ),
                RoundingAdaptiveHandoffRequestAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 64547.9
        )
    }
}
