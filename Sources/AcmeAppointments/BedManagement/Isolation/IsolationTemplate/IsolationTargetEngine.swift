import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the isolation target calculation.
    protocol IsolationTargetStep {
        func describe() -> String
        func adjust(_ item: IsolationTarget, value: Double) -> Double
    }

    final class ChannelIsolationTargetAdjuster: IsolationTargetStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: IsolationTarget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentIsolationTargetAdjuster: IsolationTargetStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: IsolationTarget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapIsolationTargetAdjuster: IsolationTargetStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: IsolationTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class IsolationTargetSequenceOffsetAdjuster: IsolationTargetStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus sequence times \(weight)"
        }

        func adjust(_ item: IsolationTarget, value: Double) -> Double {
            return value + Double(item.sequence) * weight
        }
    }

    /// Runs the isolation target steps in order and keeps a trace of each.
    final class IsolationTargetEngine {
        var steps: [any IsolationTargetStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any IsolationTargetStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: IsolationTarget) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any IsolationTargetStep = steps[index]
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

        func evaluateAll(_ items: [IsolationTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultIsolationTargetEngine() -> IsolationTargetEngine {
        return IsolationTargetEngine(
            steps: [
                ChannelIsolationTargetAdjuster(factors: ["online": 0.81, "central": 0.92, "retail": 1.16]),
                PercentIsolationTargetAdjuster(percent: -13.5),
                CapIsolationTargetAdjuster(cap: 8799.0),
                IsolationTargetSequenceOffsetAdjuster(weight: 0.92),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 73142.8
        )
    }
}
