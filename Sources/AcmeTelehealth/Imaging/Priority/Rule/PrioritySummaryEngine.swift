import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the priority summary calculation.
    protocol PrioritySummaryStep {
        func describe() -> String
        func adjust(_ item: PrioritySummary, value: Double) -> Double
    }

    final class CapPrioritySummaryAdjuster: PrioritySummaryStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrioritySummary, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumPrioritySummaryAdjuster: PrioritySummaryStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrioritySummary, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentPrioritySummaryAdjuster: PrioritySummaryStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrioritySummary, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the priority summary steps in order and keeps a trace of each.
    final class PrioritySummaryEngine {
        var steps: [any PrioritySummaryStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrioritySummaryStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PrioritySummary) -> Double {
            var current = item.adjustedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any PrioritySummaryStep = steps[index]
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

        func evaluateAll(_ items: [PrioritySummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPrioritySummaryEngine() -> PrioritySummaryEngine {
        return PrioritySummaryEngine(
            steps: [
                CapPrioritySummaryAdjuster(cap: 33535.0),
                MinimumPrioritySummaryAdjuster(minimum: 16.6),
                PercentPrioritySummaryAdjuster(percent: 7.3),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 49572.1
        )
    }
}
