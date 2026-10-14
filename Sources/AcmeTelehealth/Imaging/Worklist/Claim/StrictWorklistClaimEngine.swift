import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the strict worklist claim calculation.
    protocol StrictWorklistClaimFactor {
        func describe() -> String
        func adjust(_ item: StrictWorklistClaim, value: Double) -> Double
    }

    final class TieredStrictWorklistClaimAdjuster: StrictWorklistClaimFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictWorklistClaim, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumStrictWorklistClaimAdjuster: StrictWorklistClaimFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictWorklistClaim, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingStrictWorklistClaimAdjuster: StrictWorklistClaimFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictWorklistClaim, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentStrictWorklistClaimAdjuster: StrictWorklistClaimFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StrictWorklistClaim, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapStrictWorklistClaimAdjuster: StrictWorklistClaimFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StrictWorklistClaim, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the strict worklist claim steps in order and keeps a trace of each.
    final class StrictWorklistClaimEngine {
        var steps: [any StrictWorklistClaimFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictWorklistClaimFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: StrictWorklistClaim) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any StrictWorklistClaimFactor = steps[index]
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

        func evaluateAll(_ items: [StrictWorklistClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultStrictWorklistClaimEngine() -> StrictWorklistClaimEngine {
        return StrictWorklistClaimEngine(
            steps: [
                TieredStrictWorklistClaimAdjuster(bounds: [3772.0, 4392.0], rates: [1.15, 0.96]),
                MinimumStrictWorklistClaimAdjuster(minimum: 27.0),
                RoundingStrictWorklistClaimAdjuster(step: 0.25),
                PercentStrictWorklistClaimAdjuster(percent: 6.9),
                CapStrictWorklistClaimAdjuster(cap: 8009.0),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 28518.2
        )
    }
}
