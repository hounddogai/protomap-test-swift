import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the global isolation window calculation.
    protocol GlobalIsolationWindowStep {
        func describe() -> String
        func adjust(_ item: GlobalIsolationWindow, value: Double) -> Double
    }

    final class GlobalIsolationWindowRevisionOffsetAdjuster: GlobalIsolationWindowStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus revision times \(weight)"
        }

        func adjust(_ item: GlobalIsolationWindow, value: Double) -> Double {
            return value + Double(item.revision) * weight
        }
    }

    final class CapGlobalIsolationWindowAdjuster: GlobalIsolationWindowStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalIsolationWindow, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumGlobalIsolationWindowAdjuster: GlobalIsolationWindowStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalIsolationWindow, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LabelGlobalIsolationWindowAdjuster: GlobalIsolationWindowStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: GlobalIsolationWindow, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the global isolation window steps in order and keeps a trace of each.
    final class GlobalIsolationWindowEngine {
        var steps: [any GlobalIsolationWindowStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalIsolationWindowStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: GlobalIsolationWindow) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalIsolationWindowStep = steps[index]
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

        func evaluateAll(_ items: [GlobalIsolationWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultGlobalIsolationWindowEngine() -> GlobalIsolationWindowEngine {
        return GlobalIsolationWindowEngine(
            steps: [
                GlobalIsolationWindowRevisionOffsetAdjuster(weight: 0.31),
                CapGlobalIsolationWindowAdjuster(cap: 17387.0),
                MinimumGlobalIsolationWindowAdjuster(minimum: 24.3),
                LabelGlobalIsolationWindowAdjuster(factors: ["south": 0.92, "central": 1.32, "north": 0.91]),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 37405.7
        )
    }
}
