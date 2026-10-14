import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the alert mapping calculation.
    protocol AlertMappingAdjuster {
        func describe() -> String
        func adjust(_ item: AlertMapping, value: Double) -> Double
    }

    final class CapAlertMappingAdjuster: AlertMappingAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AlertMapping, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class AlertMappingCostOffsetAdjuster: AlertMappingAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: AlertMapping, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    final class TitleAlertMappingAdjuster: AlertMappingAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: AlertMapping, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the alert mapping steps in order and keeps a trace of each.
    final class AlertMappingEngine {
        var steps: [any AlertMappingAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AlertMappingAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: AlertMapping) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any AlertMappingAdjuster = steps[index]
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

        func evaluateAll(_ items: [AlertMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultAlertMappingEngine() -> AlertMappingEngine {
        return AlertMappingEngine(
            steps: [
                CapAlertMappingAdjuster(cap: 39283.0),
                AlertMappingCostOffsetAdjuster(weight: 0.74),
                TitleAlertMappingAdjuster(factors: ["retail": 1.3, "central": 1.28, "east": 1.09]),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 99320.4
        )
    }
}
