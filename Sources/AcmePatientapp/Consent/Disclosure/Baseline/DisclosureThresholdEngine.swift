import AcmePlatform
import Foundation

extension Consent {
    /// One step of the disclosure threshold calculation.
    protocol DisclosureThresholdAdjuster {
        func describe() -> String
        func adjust(_ item: DisclosureThreshold, value: Double) -> Double
    }

    final class FacilityDisclosureThresholdAdjuster: DisclosureThresholdAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: DisclosureThreshold, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingDisclosureThresholdAdjuster: DisclosureThresholdAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DisclosureThreshold, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class DisclosureThresholdRatioOffsetAdjuster: DisclosureThresholdAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: DisclosureThreshold, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    /// Runs the disclosure threshold steps in order and keeps a trace of each.
    final class DisclosureThresholdEngine {
        var steps: [any DisclosureThresholdAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DisclosureThresholdAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DisclosureThreshold) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any DisclosureThresholdAdjuster = steps[index]
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

        func evaluateAll(_ items: [DisclosureThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDisclosureThresholdEngine() -> DisclosureThresholdEngine {
        return DisclosureThresholdEngine(
            steps: [
                FacilityDisclosureThresholdAdjuster(factors: ["south": 0.86, "west": 0.85]),
                RoundingDisclosureThresholdAdjuster(step: 0.1),
                DisclosureThresholdRatioOffsetAdjuster(weight: 0.91),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 58576.7
        )
    }
}
