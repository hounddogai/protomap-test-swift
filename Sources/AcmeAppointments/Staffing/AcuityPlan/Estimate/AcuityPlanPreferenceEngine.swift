import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the acuity plan preference calculation.
    protocol AcuityPlanPreferenceStep {
        func describe() -> String
        func adjust(_ item: AcuityPlanPreference, value: Double) -> Double
    }

    final class PercentAcuityPlanPreferenceAdjuster: AcuityPlanPreferenceStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AcuityPlanPreference, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class AcuityPlanPreferenceBatchSizeOffsetAdjuster: AcuityPlanPreferenceStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: AcuityPlanPreference, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    final class FacilityAcuityPlanPreferenceAdjuster: AcuityPlanPreferenceStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: AcuityPlanPreference, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumAcuityPlanPreferenceAdjuster: AcuityPlanPreferenceStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AcuityPlanPreference, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingAcuityPlanPreferenceAdjuster: AcuityPlanPreferenceStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AcuityPlanPreference, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the acuity plan preference steps in order and keeps a trace of each.
    final class AcuityPlanPreferenceEngine {
        var steps: [any AcuityPlanPreferenceStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AcuityPlanPreferenceStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AcuityPlanPreference) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any AcuityPlanPreferenceStep = steps[index]
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

        func evaluateAll(_ items: [AcuityPlanPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAcuityPlanPreferenceEngine() -> AcuityPlanPreferenceEngine {
        return AcuityPlanPreferenceEngine(
            steps: [
                PercentAcuityPlanPreferenceAdjuster(percent: -6.0),
                AcuityPlanPreferenceBatchSizeOffsetAdjuster(weight: 1.74),
                FacilityAcuityPlanPreferenceAdjuster(factors: ["north": 1.05, "online": 1.34, "south": 1.14]),
                MinimumAcuityPlanPreferenceAdjuster(minimum: 30.5),
                RoundingAcuityPlanPreferenceAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 72267.9
        )
    }
}
