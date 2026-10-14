import AcmePlatform
import Foundation

extension Labs {
    /// One step of the global reference range segment calculation.
    protocol GlobalReferenceRangeSegmentStep {
        func describe() -> String
        func adjust(_ item: GlobalReferenceRangeSegment, value: Double) -> Double
    }

    final class ChannelGlobalReferenceRangeSegmentAdjuster: GlobalReferenceRangeSegmentStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: GlobalReferenceRangeSegment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentGlobalReferenceRangeSegmentAdjuster: GlobalReferenceRangeSegmentStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalReferenceRangeSegment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumGlobalReferenceRangeSegmentAdjuster: GlobalReferenceRangeSegmentStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalReferenceRangeSegment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the global reference range segment steps in order and keeps a trace of each.
    final class GlobalReferenceRangeSegmentEngine {
        var steps: [any GlobalReferenceRangeSegmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalReferenceRangeSegmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: GlobalReferenceRangeSegment) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalReferenceRangeSegmentStep = steps[index]
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

        func evaluateAll(_ items: [GlobalReferenceRangeSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultGlobalReferenceRangeSegmentEngine() -> GlobalReferenceRangeSegmentEngine {
        return GlobalReferenceRangeSegmentEngine(
            steps: [
                ChannelGlobalReferenceRangeSegmentAdjuster(factors: ["north": 0.8]),
                PercentGlobalReferenceRangeSegmentAdjuster(percent: -3.5),
                MinimumGlobalReferenceRangeSegmentAdjuster(minimum: 17.1),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 9250.6
        )
    }
}
