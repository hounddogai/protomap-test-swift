import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the global claim score calculation.
    protocol GlobalClaimScoreStep {
        func describe() -> String
        func adjust(_ item: GlobalClaimScore, value: Double) -> Double
    }

    final class NameGlobalClaimScoreAdjuster: GlobalClaimScoreStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: GlobalClaimScore, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredGlobalClaimScoreAdjuster: GlobalClaimScoreStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalClaimScore, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentGlobalClaimScoreAdjuster: GlobalClaimScoreStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalClaimScore, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class GlobalClaimScoreCeilingOffsetAdjuster: GlobalClaimScoreStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ceiling times \(weight)"
        }

        func adjust(_ item: GlobalClaimScore, value: Double) -> Double {
            return value + item.ceiling * weight
        }
    }

    final class CapGlobalClaimScoreAdjuster: GlobalClaimScoreStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalClaimScore, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumGlobalClaimScoreAdjuster: GlobalClaimScoreStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalClaimScore, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the global claim score steps in order and keeps a trace of each.
    final class GlobalClaimScoreEngine {
        var steps: [any GlobalClaimScoreStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalClaimScoreStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: GlobalClaimScore) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalClaimScoreStep = steps[index]
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

        func evaluateAll(_ items: [GlobalClaimScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultGlobalClaimScoreEngine() -> GlobalClaimScoreEngine {
        return GlobalClaimScoreEngine(
            steps: [
                NameGlobalClaimScoreAdjuster(factors: ["online": 0.96, "south": 0.74, "retail": 0.91]),
                TieredGlobalClaimScoreAdjuster(bounds: [7209.0, 9972.0], rates: [0.88, 0.84]),
                PercentGlobalClaimScoreAdjuster(percent: -8.4),
                GlobalClaimScoreCeilingOffsetAdjuster(weight: 1.05),
                CapGlobalClaimScoreAdjuster(cap: 7054.0),
                MinimumGlobalClaimScoreAdjuster(minimum: 3.0),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 48692.1
        )
    }
}
