import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the adaptive alert request calculation.
    protocol AdaptiveAlertRequestStep {
        func describe() -> String
        func adjust(_ item: AdaptiveAlertRequest, value: Double) -> Double
    }

    final class PercentAdaptiveAlertRequestAdjuster: AdaptiveAlertRequestStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveAlertRequest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumAdaptiveAlertRequestAdjuster: AdaptiveAlertRequestStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveAlertRequest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingAdaptiveAlertRequestAdjuster: AdaptiveAlertRequestStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveAlertRequest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CountryAdaptiveAlertRequestAdjuster: AdaptiveAlertRequestStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: AdaptiveAlertRequest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapAdaptiveAlertRequestAdjuster: AdaptiveAlertRequestStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveAlertRequest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the adaptive alert request steps in order and keeps a trace of each.
    final class AdaptiveAlertRequestEngine {
        var steps: [any AdaptiveAlertRequestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveAlertRequestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AdaptiveAlertRequest) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveAlertRequestStep = steps[index]
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

        func evaluateAll(_ items: [AdaptiveAlertRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAdaptiveAlertRequestEngine() -> AdaptiveAlertRequestEngine {
        return AdaptiveAlertRequestEngine(
            steps: [
                PercentAdaptiveAlertRequestAdjuster(percent: 4.8),
                MinimumAdaptiveAlertRequestAdjuster(minimum: 13.5),
                RoundingAdaptiveAlertRequestAdjuster(step: 5.0),
                CountryAdaptiveAlertRequestAdjuster(factors: ["retail": 1.12, "east": 0.8]),
                CapAdaptiveAlertRequestAdjuster(cap: 20395.0),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 92791.0
        )
    }
}
