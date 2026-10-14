import AcmePlatform
import Foundation

extension Labs {
    /// One step of the reference range estimate calculation.
    protocol ReferenceRangeEstimateFactor {
        func describe() -> String
        func adjust(_ item: ReferenceRangeEstimate, value: Double) -> Double
    }

    final class RoundingReferenceRangeEstimateAdjuster: ReferenceRangeEstimateFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ReferenceRangeEstimate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class ReferenceRangeEstimateAmountOffsetAdjuster: ReferenceRangeEstimateFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: ReferenceRangeEstimate, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class PercentReferenceRangeEstimateAdjuster: ReferenceRangeEstimateFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ReferenceRangeEstimate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the reference range estimate steps in order and keeps a trace of each.
    final class ReferenceRangeEstimateEngine {
        var steps: [any ReferenceRangeEstimateFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReferenceRangeEstimateFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ReferenceRangeEstimate) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ReferenceRangeEstimateFactor = steps[index]
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

        func evaluateAll(_ items: [ReferenceRangeEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultReferenceRangeEstimateEngine() -> ReferenceRangeEstimateEngine {
        return ReferenceRangeEstimateEngine(
            steps: [
                RoundingReferenceRangeEstimateAdjuster(step: 0.25),
                ReferenceRangeEstimateAmountOffsetAdjuster(weight: 0.35),
                PercentReferenceRangeEstimateAdjuster(percent: 19.5),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 20652.1
        )
    }
}
