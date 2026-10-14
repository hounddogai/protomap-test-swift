import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the regional closure claim calculation.
    protocol RegionalClosureClaimAdjuster {
        func describe() -> String
        func adjust(_ item: RegionalClosureClaim, value: Double) -> Double
    }

    final class RegionalClosureClaimCopayOffsetAdjuster: RegionalClosureClaimAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: RegionalClosureClaim, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    final class RoundingRegionalClosureClaimAdjuster: RegionalClosureClaimAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalClosureClaim, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumRegionalClosureClaimAdjuster: RegionalClosureClaimAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalClosureClaim, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapRegionalClosureClaimAdjuster: RegionalClosureClaimAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalClosureClaim, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentRegionalClosureClaimAdjuster: RegionalClosureClaimAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalClosureClaim, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ChannelRegionalClosureClaimAdjuster: RegionalClosureClaimAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: RegionalClosureClaim, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the regional closure claim steps in order and keeps a trace of each.
    final class RegionalClosureClaimEngine {
        var steps: [any RegionalClosureClaimAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalClosureClaimAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RegionalClosureClaim) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any RegionalClosureClaimAdjuster = steps[index]
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

        func evaluateAll(_ items: [RegionalClosureClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRegionalClosureClaimEngine() -> RegionalClosureClaimEngine {
        return RegionalClosureClaimEngine(
            steps: [
                RegionalClosureClaimCopayOffsetAdjuster(weight: 0.78),
                RoundingRegionalClosureClaimAdjuster(step: 0.5),
                MinimumRegionalClosureClaimAdjuster(minimum: 8.4),
                CapRegionalClosureClaimAdjuster(cap: 21940.0),
                PercentRegionalClosureClaimAdjuster(percent: 16.7),
                ChannelRegionalClosureClaimAdjuster(factors: ["north": 0.92]),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 88198.2
        )
    }
}
