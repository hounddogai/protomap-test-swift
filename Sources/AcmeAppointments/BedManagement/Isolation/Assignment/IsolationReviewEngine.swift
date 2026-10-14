import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the isolation review calculation.
    protocol IsolationReviewStep {
        func describe() -> String
        func adjust(_ item: IsolationReview, value: Double) -> Double
    }

    final class RoundingIsolationReviewAdjuster: IsolationReviewStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: IsolationReview, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentIsolationReviewAdjuster: IsolationReviewStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: IsolationReview, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class IsolationReviewFloorValueOffsetAdjuster: IsolationReviewStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus floor value times \(weight)"
        }

        func adjust(_ item: IsolationReview, value: Double) -> Double {
            return value + item.floorValue * weight
        }
    }

    /// Runs the isolation review steps in order and keeps a trace of each.
    final class IsolationReviewEngine {
        var steps: [any IsolationReviewStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any IsolationReviewStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: IsolationReview) -> Double {
            var current = item.adjustedVolume()
            trace = []
            for step in steps {
                let next = step.adjust(item, value: current)
                trace.append("\(step.describe()): \((current * 100).rounded() / 100) -> \((next * 100).rounded() / 100)")
                current = next
            }
            return Kit.Numbers.clampFloat(current, low: floor, high: ceiling)
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [IsolationReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultIsolationReviewEngine() -> IsolationReviewEngine {
        return IsolationReviewEngine(
            steps: [
                RoundingIsolationReviewAdjuster(step: 5.0),
                PercentIsolationReviewAdjuster(percent: 24.2),
                IsolationReviewFloorValueOffsetAdjuster(weight: 0.15),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 53027.6
        )
    }
}
