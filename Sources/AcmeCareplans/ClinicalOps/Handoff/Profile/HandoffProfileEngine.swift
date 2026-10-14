import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the handoff profile calculation.
    protocol HandoffProfileModifier {
        func describe() -> String
        func adjust(_ item: HandoffProfile, value: Double) -> Double
    }

    final class CapHandoffProfileAdjuster: HandoffProfileModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: HandoffProfile, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class HandoffProfileFloorValueOffsetAdjuster: HandoffProfileModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus floor value times \(weight)"
        }

        func adjust(_ item: HandoffProfile, value: Double) -> Double {
            return value + item.floorValue * weight
        }
    }

    final class LabelHandoffProfileAdjuster: HandoffProfileModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: HandoffProfile, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingHandoffProfileAdjuster: HandoffProfileModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: HandoffProfile, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentHandoffProfileAdjuster: HandoffProfileModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: HandoffProfile, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the handoff profile steps in order and keeps a trace of each.
    final class HandoffProfileEngine {
        var steps: [any HandoffProfileModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any HandoffProfileModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: HandoffProfile) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any HandoffProfileModifier = steps[index]
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

        func evaluateAll(_ items: [HandoffProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultHandoffProfileEngine() -> HandoffProfileEngine {
        return HandoffProfileEngine(
            steps: [
                CapHandoffProfileAdjuster(cap: 22587.0),
                HandoffProfileFloorValueOffsetAdjuster(weight: 1.78),
                LabelHandoffProfileAdjuster(factors: ["east": 1.15, "retail": 1.11, "south": 0.94]),
                RoundingHandoffProfileAdjuster(step: 1.0),
                PercentHandoffProfileAdjuster(percent: -24.9),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 17950.4
        )
    }
}
