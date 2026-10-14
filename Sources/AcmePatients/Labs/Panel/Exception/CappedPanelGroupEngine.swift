import AcmePlatform
import Foundation

extension Labs {
    /// One step of the capped panel group calculation.
    protocol CappedPanelGroupFactor {
        func describe() -> String
        func adjust(_ item: CappedPanelGroup, value: Double) -> Double
    }

    final class CapCappedPanelGroupAdjuster: CappedPanelGroupFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedPanelGroup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class NameCappedPanelGroupAdjuster: CappedPanelGroupFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: CappedPanelGroup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingCappedPanelGroupAdjuster: CappedPanelGroupFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedPanelGroup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentCappedPanelGroupAdjuster: CappedPanelGroupFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedPanelGroup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the capped panel group steps in order and keeps a trace of each.
    final class CappedPanelGroupEngine {
        var steps: [any CappedPanelGroupFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedPanelGroupFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CappedPanelGroup) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedPanelGroupFactor = steps[index]
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

        func evaluateAll(_ items: [CappedPanelGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCappedPanelGroupEngine() -> CappedPanelGroupEngine {
        return CappedPanelGroupEngine(
            steps: [
                CapCappedPanelGroupAdjuster(cap: 38224.0),
                NameCappedPanelGroupAdjuster(factors: ["retail": 0.76]),
                RoundingCappedPanelGroupAdjuster(step: 0.05),
                PercentCappedPanelGroupAdjuster(percent: -10.1),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 43867.3
        )
    }
}
