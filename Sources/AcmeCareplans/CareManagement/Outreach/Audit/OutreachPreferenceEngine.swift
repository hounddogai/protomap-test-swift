import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the outreach preference calculation.
    protocol OutreachPreferenceStep {
        func describe() -> String
        func adjust(_ item: OutreachPreference, value: Double) -> Double
    }

    final class MinimumOutreachPreferenceAdjuster: OutreachPreferenceStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: OutreachPreference, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentOutreachPreferenceAdjuster: OutreachPreferenceStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: OutreachPreference, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CategoryOutreachPreferenceAdjuster: OutreachPreferenceStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: OutreachPreference, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the outreach preference steps in order and keeps a trace of each.
    final class OutreachPreferenceEngine {
        var steps: [any OutreachPreferenceStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OutreachPreferenceStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: OutreachPreference) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any OutreachPreferenceStep = steps[index]
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

        func evaluateAll(_ items: [OutreachPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultOutreachPreferenceEngine() -> OutreachPreferenceEngine {
        return OutreachPreferenceEngine(
            steps: [
                MinimumOutreachPreferenceAdjuster(minimum: 30.8),
                PercentOutreachPreferenceAdjuster(percent: 10.0),
                CategoryOutreachPreferenceAdjuster(factors: ["east": 0.85, "north": 1.29]),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 36526.9
        )
    }
}
