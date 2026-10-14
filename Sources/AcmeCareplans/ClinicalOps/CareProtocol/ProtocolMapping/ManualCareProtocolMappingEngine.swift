import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the manual care protocol mapping calculation.
    protocol ManualCareProtocolMappingStep {
        func describe() -> String
        func adjust(_ item: ManualCareProtocolMapping, value: Double) -> Double
    }

    final class ManualCareProtocolMappingCostOffsetAdjuster: ManualCareProtocolMappingStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: ManualCareProtocolMapping, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    final class RoundingManualCareProtocolMappingAdjuster: ManualCareProtocolMappingStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualCareProtocolMapping, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumManualCareProtocolMappingAdjuster: ManualCareProtocolMappingStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualCareProtocolMapping, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentManualCareProtocolMappingAdjuster: ManualCareProtocolMappingStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualCareProtocolMapping, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the manual care protocol mapping steps in order and keeps a trace of each.
    final class ManualCareProtocolMappingEngine {
        var steps: [any ManualCareProtocolMappingStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualCareProtocolMappingStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ManualCareProtocolMapping) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualCareProtocolMappingStep = steps[index]
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

        func evaluateAll(_ items: [ManualCareProtocolMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultManualCareProtocolMappingEngine() -> ManualCareProtocolMappingEngine {
        return ManualCareProtocolMappingEngine(
            steps: [
                ManualCareProtocolMappingCostOffsetAdjuster(weight: 0.17),
                RoundingManualCareProtocolMappingAdjuster(step: 1.0),
                MinimumManualCareProtocolMappingAdjuster(minimum: 8.3),
                PercentManualCareProtocolMappingAdjuster(percent: 8.7),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 79668.0
        )
    }
}
