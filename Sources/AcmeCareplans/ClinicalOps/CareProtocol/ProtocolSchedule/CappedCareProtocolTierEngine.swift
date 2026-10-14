import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the capped care protocol tier calculation.
    protocol CappedCareProtocolTierStep {
        func describe() -> String
        func adjust(_ item: CappedCareProtocolTier, value: Double) -> Double
    }

    final class CapCappedCareProtocolTierAdjuster: CappedCareProtocolTierStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedCareProtocolTier, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingCappedCareProtocolTierAdjuster: CappedCareProtocolTierStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedCareProtocolTier, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentCappedCareProtocolTierAdjuster: CappedCareProtocolTierStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedCareProtocolTier, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the capped care protocol tier steps in order and keeps a trace of each.
    final class CappedCareProtocolTierEngine {
        var steps: [any CappedCareProtocolTierStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedCareProtocolTierStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CappedCareProtocolTier) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedCareProtocolTierStep = steps[index]
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

        func evaluateAll(_ items: [CappedCareProtocolTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCappedCareProtocolTierEngine() -> CappedCareProtocolTierEngine {
        return CappedCareProtocolTierEngine(
            steps: [
                CapCappedCareProtocolTierAdjuster(cap: 19038.0),
                RoundingCappedCareProtocolTierAdjuster(step: 1.0),
                PercentCappedCareProtocolTierAdjuster(percent: -12.4),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 11538.9
        )
    }
}
