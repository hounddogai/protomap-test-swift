import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the default interaction segment calculation.
    protocol DefaultInteractionSegmentModifier {
        func describe() -> String
        func adjust(_ item: DefaultInteractionSegment, value: Double) -> Double
    }

    final class MinimumDefaultInteractionSegmentAdjuster: DefaultInteractionSegmentModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultInteractionSegment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentDefaultInteractionSegmentAdjuster: DefaultInteractionSegmentModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultInteractionSegment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SourceDefaultInteractionSegmentAdjuster: DefaultInteractionSegmentModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: DefaultInteractionSegment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the default interaction segment steps in order and keeps a trace of each.
    final class DefaultInteractionSegmentEngine {
        var steps: [any DefaultInteractionSegmentModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultInteractionSegmentModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DefaultInteractionSegment) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultInteractionSegmentModifier = steps[index]
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

        func evaluateAll(_ items: [DefaultInteractionSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDefaultInteractionSegmentEngine() -> DefaultInteractionSegmentEngine {
        return DefaultInteractionSegmentEngine(
            steps: [
                MinimumDefaultInteractionSegmentAdjuster(minimum: 25.3),
                PercentDefaultInteractionSegmentAdjuster(percent: 1.8),
                SourceDefaultInteractionSegmentAdjuster(factors: ["south": 0.91, "west": 1.21]),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 15595.0
        )
    }
}
