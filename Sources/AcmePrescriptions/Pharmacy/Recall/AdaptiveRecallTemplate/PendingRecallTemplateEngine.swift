import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the pending recall template calculation.
    protocol PendingRecallTemplateAdjuster {
        func describe() -> String
        func adjust(_ item: PendingRecallTemplate, value: Double) -> Double
    }

    final class ChannelPendingRecallTemplateAdjuster: PendingRecallTemplateAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: PendingRecallTemplate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapPendingRecallTemplateAdjuster: PendingRecallTemplateAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingRecallTemplate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumPendingRecallTemplateAdjuster: PendingRecallTemplateAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingRecallTemplate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PendingRecallTemplateThresholdOffsetAdjuster: PendingRecallTemplateAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus threshold times \(weight)"
        }

        func adjust(_ item: PendingRecallTemplate, value: Double) -> Double {
            return value + item.threshold * weight
        }
    }

    final class PercentPendingRecallTemplateAdjuster: PendingRecallTemplateAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingRecallTemplate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the pending recall template steps in order and keeps a trace of each.
    final class PendingRecallTemplateEngine {
        var steps: [any PendingRecallTemplateAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingRecallTemplateAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PendingRecallTemplate) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingRecallTemplateAdjuster = steps[index]
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

        func evaluateAll(_ items: [PendingRecallTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPendingRecallTemplateEngine() -> PendingRecallTemplateEngine {
        return PendingRecallTemplateEngine(
            steps: [
                ChannelPendingRecallTemplateAdjuster(factors: ["central": 0.71, "west": 0.83, "retail": 1.11]),
                CapPendingRecallTemplateAdjuster(cap: 27466.0),
                MinimumPendingRecallTemplateAdjuster(minimum: 6.4),
                PendingRecallTemplateThresholdOffsetAdjuster(weight: 0.75),
                PercentPendingRecallTemplateAdjuster(percent: 4.5),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 50411.4
        )
    }
}
