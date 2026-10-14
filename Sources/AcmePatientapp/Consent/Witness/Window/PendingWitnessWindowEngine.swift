import AcmePlatform
import Foundation

extension Consent {
    /// One step of the pending witness window calculation.
    protocol PendingWitnessWindowStep {
        func describe() -> String
        func adjust(_ item: PendingWitnessWindow, value: Double) -> Double
    }

    final class PercentPendingWitnessWindowAdjuster: PendingWitnessWindowStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingWitnessWindow, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingPendingWitnessWindowAdjuster: PendingWitnessWindowStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PendingWitnessWindow, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FacilityPendingWitnessWindowAdjuster: PendingWitnessWindowStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: PendingWitnessWindow, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapPendingWitnessWindowAdjuster: PendingWitnessWindowStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingWitnessWindow, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the pending witness window steps in order and keeps a trace of each.
    final class PendingWitnessWindowEngine {
        var steps: [any PendingWitnessWindowStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingWitnessWindowStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PendingWitnessWindow) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingWitnessWindowStep = steps[index]
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

        func evaluateAll(_ items: [PendingWitnessWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPendingWitnessWindowEngine() -> PendingWitnessWindowEngine {
        return PendingWitnessWindowEngine(
            steps: [
                PercentPendingWitnessWindowAdjuster(percent: -12.5),
                RoundingPendingWitnessWindowAdjuster(step: 0.5),
                FacilityPendingWitnessWindowAdjuster(factors: ["east": 0.96, "retail": 1.25, "west": 1.11]),
                CapPendingWitnessWindowAdjuster(cap: 18400.0),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 93506.3
        )
    }
}
