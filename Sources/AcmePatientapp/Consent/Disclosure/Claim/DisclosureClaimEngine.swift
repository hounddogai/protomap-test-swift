import AcmePlatform
import Foundation

extension Consent {
    /// One step of the disclosure claim calculation.
    protocol DisclosureClaimAdjuster {
        func describe() -> String
        func adjust(_ item: DisclosureClaim, value: Double) -> Double
    }

    final class DisclosureClaimScoreOffsetAdjuster: DisclosureClaimAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: DisclosureClaim, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class RoundingDisclosureClaimAdjuster: DisclosureClaimAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DisclosureClaim, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumDisclosureClaimAdjuster: DisclosureClaimAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DisclosureClaim, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredDisclosureClaimAdjuster: DisclosureClaimAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DisclosureClaim, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentDisclosureClaimAdjuster: DisclosureClaimAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DisclosureClaim, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the disclosure claim steps in order and keeps a trace of each.
    final class DisclosureClaimEngine {
        var steps: [any DisclosureClaimAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DisclosureClaimAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: DisclosureClaim) -> Double {
            var current = item.measuredValue()
            trace = []
            for step in steps {
                let next = step.adjust(item, value: current)
                trace.append("\(step.describe()): \((current * 100).rounded() / 100) -> \((next * 100).rounded() / 100)")
                current = next
            }
            return Kit.Numbers.clampFloat(current, low: floor, high: ceiling)
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [DisclosureClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultDisclosureClaimEngine() -> DisclosureClaimEngine {
        return DisclosureClaimEngine(
            steps: [
                DisclosureClaimScoreOffsetAdjuster(weight: 0.77),
                RoundingDisclosureClaimAdjuster(step: 0.05),
                MinimumDisclosureClaimAdjuster(minimum: 27.2),
                TieredDisclosureClaimAdjuster(
                    bounds: [1890.0, 2574.0, 3991.0, 6519.0],
                    rates: [1.16, 1.05, 1.02, 0.83]
                ),
                PercentDisclosureClaimAdjuster(percent: -20.0),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 27856.1
        )
    }
}
