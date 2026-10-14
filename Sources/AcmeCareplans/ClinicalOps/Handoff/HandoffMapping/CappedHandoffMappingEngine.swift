import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the capped handoff mapping calculation.
    protocol CappedHandoffMappingStep {
        func describe() -> String
        func adjust(_ item: CappedHandoffMapping, value: Double) -> Double
    }

    final class PercentCappedHandoffMappingAdjuster: CappedHandoffMappingStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedHandoffMapping, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CappedHandoffMappingWeightOffsetAdjuster: CappedHandoffMappingStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus weight times \(weight)"
        }

        func adjust(_ item: CappedHandoffMapping, value: Double) -> Double {
            return value + item.weight * weight
        }
    }

    final class NameCappedHandoffMappingAdjuster: CappedHandoffMappingStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: CappedHandoffMapping, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the capped handoff mapping steps in order and keeps a trace of each.
    final class CappedHandoffMappingEngine {
        var steps: [any CappedHandoffMappingStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedHandoffMappingStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CappedHandoffMapping) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedHandoffMappingStep = steps[index]
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

        func evaluateAll(_ items: [CappedHandoffMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCappedHandoffMappingEngine() -> CappedHandoffMappingEngine {
        return CappedHandoffMappingEngine(
            steps: [
                PercentCappedHandoffMappingAdjuster(percent: 14.6),
                CappedHandoffMappingWeightOffsetAdjuster(weight: 1.37),
                NameCappedHandoffMappingAdjuster(factors: ["north": 1.06, "central": 1.01, "east": 0.82]),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 24947.3
        )
    }
}
