import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the adaptive priority audit calculation.
    protocol AdaptivePriorityAuditAdjuster {
        func describe() -> String
        func adjust(_ item: AdaptivePriorityAudit, value: Double) -> Double
    }

    final class ChannelAdaptivePriorityAuditAdjuster: AdaptivePriorityAuditAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: AdaptivePriorityAudit, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentAdaptivePriorityAuditAdjuster: AdaptivePriorityAuditAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptivePriorityAudit, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class AdaptivePriorityAuditAttemptsOffsetAdjuster: AdaptivePriorityAuditAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: AdaptivePriorityAudit, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    /// Runs the adaptive priority audit steps in order and keeps a trace of each.
    final class AdaptivePriorityAuditEngine {
        var steps: [any AdaptivePriorityAuditAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptivePriorityAuditAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AdaptivePriorityAudit) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptivePriorityAuditAdjuster = steps[index]
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

        func evaluateAll(_ items: [AdaptivePriorityAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAdaptivePriorityAuditEngine() -> AdaptivePriorityAuditEngine {
        return AdaptivePriorityAuditEngine(
            steps: [
                ChannelAdaptivePriorityAuditAdjuster(factors: ["online": 1.19, "north": 1.39]),
                PercentAdaptivePriorityAuditAdjuster(percent: -24.7),
                AdaptivePriorityAuditAttemptsOffsetAdjuster(weight: 1.48),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 85924.2
        )
    }
}
