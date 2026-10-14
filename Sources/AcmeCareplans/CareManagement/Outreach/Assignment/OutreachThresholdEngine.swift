import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the outreach threshold calculation.
    protocol OutreachThresholdModifier {
        func describe() -> String
        func adjust(_ item: OutreachThreshold, value: Double) -> Double
    }

    final class PercentOutreachThresholdAdjuster: OutreachThresholdModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: OutreachThreshold, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class WardOutreachThresholdAdjuster: OutreachThresholdModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: OutreachThreshold, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumOutreachThresholdAdjuster: OutreachThresholdModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: OutreachThreshold, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the outreach threshold steps in order and keeps a trace of each.
    final class OutreachThresholdEngine {
        var steps: [any OutreachThresholdModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OutreachThresholdModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: OutreachThreshold) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any OutreachThresholdModifier = steps[index]
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

        func evaluateAll(_ items: [OutreachThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultOutreachThresholdEngine() -> OutreachThresholdEngine {
        return OutreachThresholdEngine(
            steps: [
                PercentOutreachThresholdAdjuster(percent: -4.0),
                WardOutreachThresholdAdjuster(factors: ["retail": 1.12]),
                MinimumOutreachThresholdAdjuster(minimum: 0.9),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 20461.5
        )
    }
}
