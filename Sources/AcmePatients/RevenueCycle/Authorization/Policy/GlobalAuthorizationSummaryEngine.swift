import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the global authorization summary calculation.
    protocol GlobalAuthorizationSummaryStep {
        func describe() -> String
        func adjust(_ item: GlobalAuthorizationSummary, value: Double) -> Double
    }

    final class TieredGlobalAuthorizationSummaryAdjuster: GlobalAuthorizationSummaryStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalAuthorizationSummary, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapGlobalAuthorizationSummaryAdjuster: GlobalAuthorizationSummaryStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalAuthorizationSummary, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FacilityGlobalAuthorizationSummaryAdjuster: GlobalAuthorizationSummaryStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: GlobalAuthorizationSummary, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class GlobalAuthorizationSummaryCapacityOffsetAdjuster: GlobalAuthorizationSummaryStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: GlobalAuthorizationSummary, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    final class PercentGlobalAuthorizationSummaryAdjuster: GlobalAuthorizationSummaryStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalAuthorizationSummary, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the global authorization summary steps in order and keeps a trace of each.
    final class GlobalAuthorizationSummaryEngine {
        var steps: [any GlobalAuthorizationSummaryStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalAuthorizationSummaryStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: GlobalAuthorizationSummary) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalAuthorizationSummaryStep = steps[index]
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

        func evaluateAll(_ items: [GlobalAuthorizationSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultGlobalAuthorizationSummaryEngine() -> GlobalAuthorizationSummaryEngine {
        return GlobalAuthorizationSummaryEngine(
            steps: [
                TieredGlobalAuthorizationSummaryAdjuster(
                    bounds: [7424.0, 7801.0, 9148.0, 9576.0],
                    rates: [0.83, 0.97, 0.94, 0.98]
                ),
                CapGlobalAuthorizationSummaryAdjuster(cap: 3646.0),
                FacilityGlobalAuthorizationSummaryAdjuster(factors: ["east": 0.73, "south": 0.77]),
                GlobalAuthorizationSummaryCapacityOffsetAdjuster(weight: 0.44),
                PercentGlobalAuthorizationSummaryAdjuster(percent: 23.9),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 69190.2
        )
    }
}
