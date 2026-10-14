import AcmePlatform
import Foundation

extension Labs {
    /// One step of the reference range threshold calculation.
    protocol ReferenceRangeThresholdFactor {
        func describe() -> String
        func adjust(_ item: ReferenceRangeThreshold, value: Double) -> Double
    }

    final class MinimumReferenceRangeThresholdAdjuster: ReferenceRangeThresholdFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ReferenceRangeThreshold, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapReferenceRangeThresholdAdjuster: ReferenceRangeThresholdFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ReferenceRangeThreshold, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class ReferenceRangeThresholdWindowDaysOffsetAdjuster: ReferenceRangeThresholdFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: ReferenceRangeThreshold, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    final class LocaleReferenceRangeThresholdAdjuster: ReferenceRangeThresholdFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: ReferenceRangeThreshold, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the reference range threshold steps in order and keeps a trace of each.
    final class ReferenceRangeThresholdEngine {
        var steps: [any ReferenceRangeThresholdFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReferenceRangeThresholdFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ReferenceRangeThreshold) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any ReferenceRangeThresholdFactor = steps[index]
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

        func evaluateAll(_ items: [ReferenceRangeThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultReferenceRangeThresholdEngine() -> ReferenceRangeThresholdEngine {
        return ReferenceRangeThresholdEngine(
            steps: [
                MinimumReferenceRangeThresholdAdjuster(minimum: 20.5),
                CapReferenceRangeThresholdAdjuster(cap: 24690.0),
                ReferenceRangeThresholdWindowDaysOffsetAdjuster(weight: 1.51),
                LocaleReferenceRangeThresholdAdjuster(factors: ["north": 0.79]),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 17699.9
        )
    }
}
