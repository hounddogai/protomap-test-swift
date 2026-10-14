import AcmePlatform
import Foundation

extension Consent {
    /// One step of the capped disclosure target calculation.
    protocol CappedDisclosureTargetStep {
        func describe() -> String
        func adjust(_ item: CappedDisclosureTarget, value: Double) -> Double
    }

    final class CapCappedDisclosureTargetAdjuster: CappedDisclosureTargetStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedDisclosureTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentCappedDisclosureTargetAdjuster: CappedDisclosureTargetStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedDisclosureTarget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingCappedDisclosureTargetAdjuster: CappedDisclosureTargetStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedDisclosureTarget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class WardCappedDisclosureTargetAdjuster: CappedDisclosureTargetStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: CappedDisclosureTarget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredCappedDisclosureTargetAdjuster: CappedDisclosureTargetStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedDisclosureTarget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumCappedDisclosureTargetAdjuster: CappedDisclosureTargetStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedDisclosureTarget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the capped disclosure target steps in order and keeps a trace of each.
    final class CappedDisclosureTargetEngine {
        var steps: [any CappedDisclosureTargetStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedDisclosureTargetStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CappedDisclosureTarget) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedDisclosureTargetStep = steps[index]
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

        func evaluateAll(_ items: [CappedDisclosureTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCappedDisclosureTargetEngine() -> CappedDisclosureTargetEngine {
        return CappedDisclosureTargetEngine(
            steps: [
                CapCappedDisclosureTargetAdjuster(cap: 1437.0),
                PercentCappedDisclosureTargetAdjuster(percent: 1.2),
                RoundingCappedDisclosureTargetAdjuster(step: 5.0),
                WardCappedDisclosureTargetAdjuster(factors: ["south": 0.7, "west": 1.36, "central": 1.36]),
                TieredCappedDisclosureTargetAdjuster(
                    bounds: [315.0, 534.0, 2861.0, 9995.0],
                    rates: [1.19, 1.09, 1.18, 0.89]
                ),
                MinimumCappedDisclosureTargetAdjuster(minimum: 44.7),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 5702.2
        )
    }
}
