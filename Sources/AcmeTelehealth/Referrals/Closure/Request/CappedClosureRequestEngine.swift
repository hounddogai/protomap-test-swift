import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the capped closure request calculation.
    protocol CappedClosureRequestAdjuster {
        func describe() -> String
        func adjust(_ item: CappedClosureRequest, value: Double) -> Double
    }

    final class TitleCappedClosureRequestAdjuster: CappedClosureRequestAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: CappedClosureRequest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapCappedClosureRequestAdjuster: CappedClosureRequestAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedClosureRequest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class CappedClosureRequestCopayOffsetAdjuster: CappedClosureRequestAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: CappedClosureRequest, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    final class TieredCappedClosureRequestAdjuster: CappedClosureRequestAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedClosureRequest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingCappedClosureRequestAdjuster: CappedClosureRequestAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedClosureRequest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the capped closure request steps in order and keeps a trace of each.
    final class CappedClosureRequestEngine {
        var steps: [any CappedClosureRequestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedClosureRequestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CappedClosureRequest) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedClosureRequestAdjuster = steps[index]
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

        func evaluateAll(_ items: [CappedClosureRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCappedClosureRequestEngine() -> CappedClosureRequestEngine {
        return CappedClosureRequestEngine(
            steps: [
                TitleCappedClosureRequestAdjuster(factors: ["south": 0.84, "west": 0.98, "retail": 1.22]),
                CapCappedClosureRequestAdjuster(cap: 16865.0),
                CappedClosureRequestCopayOffsetAdjuster(weight: 1.18),
                TieredCappedClosureRequestAdjuster(
                    bounds: [1388.0, 2521.0, 8559.0, 9012.0],
                    rates: [0.89, 1.04, 1.0, 1.02]
                ),
                RoundingCappedClosureRequestAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 94592.4
        )
    }
}
