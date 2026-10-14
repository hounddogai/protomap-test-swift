import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the recall claim calculation.
    protocol RecallClaimAdjuster {
        func describe() -> String
        func adjust(_ item: RecallClaim, value: Double) -> Double
    }

    final class PercentRecallClaimAdjuster: RecallClaimAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RecallClaim, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapRecallClaimAdjuster: RecallClaimAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RecallClaim, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredRecallClaimAdjuster: RecallClaimAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RecallClaim, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the recall claim steps in order and keeps a trace of each.
    final class RecallClaimEngine {
        var steps: [any RecallClaimAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RecallClaimAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RecallClaim) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RecallClaimAdjuster = steps[index]
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

        func evaluateAll(_ items: [RecallClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRecallClaimEngine() -> RecallClaimEngine {
        return RecallClaimEngine(
            steps: [
                PercentRecallClaimAdjuster(percent: -19.2),
                CapRecallClaimAdjuster(cap: 35160.0),
                TieredRecallClaimAdjuster(bounds: [784.0, 6171.0], rates: [1.16, 1.05]),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 40298.6
        )
    }
}
