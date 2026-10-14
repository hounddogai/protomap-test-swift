import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the denial variance calculation.
    protocol DenialVarianceModifier {
        func describe() -> String
        func adjust(_ item: DenialVariance, value: Double) -> Double
    }

    final class PercentDenialVarianceAdjuster: DenialVarianceModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DenialVariance, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FacilityDenialVarianceAdjuster: DenialVarianceModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: DenialVariance, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapDenialVarianceAdjuster: DenialVarianceModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DenialVariance, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the denial variance steps in order and keeps a trace of each.
    final class DenialVarianceEngine {
        var steps: [any DenialVarianceModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DenialVarianceModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DenialVariance) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any DenialVarianceModifier = steps[index]
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

        func evaluateAll(_ items: [DenialVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDenialVarianceEngine() -> DenialVarianceEngine {
        return DenialVarianceEngine(
            steps: [
                PercentDenialVarianceAdjuster(percent: 16.8),
                FacilityDenialVarianceAdjuster(factors: ["online": 0.73, "south": 1.26]),
                CapDenialVarianceAdjuster(cap: 27088.0),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 74781.2
        )
    }
}
