import AcmePlatform
import Foundation

extension Labs {
    /// One step of the capped accession window calculation.
    protocol CappedAccessionWindowAdjuster {
        func describe() -> String
        func adjust(_ item: CappedAccessionWindow, value: Double) -> Double
    }

    final class PercentCappedAccessionWindowAdjuster: CappedAccessionWindowAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedAccessionWindow, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingCappedAccessionWindowAdjuster: CappedAccessionWindowAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedAccessionWindow, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumCappedAccessionWindowAdjuster: CappedAccessionWindowAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedAccessionWindow, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapCappedAccessionWindowAdjuster: CappedAccessionWindowAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedAccessionWindow, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class CappedAccessionWindowDosageMgOffsetAdjuster: CappedAccessionWindowAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus dosage mg times \(weight)"
        }

        func adjust(_ item: CappedAccessionWindow, value: Double) -> Double {
            return value + item.dosageMg * weight
        }
    }

    /// Runs the capped accession window steps in order and keeps a trace of each.
    final class CappedAccessionWindowEngine {
        var steps: [any CappedAccessionWindowAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedAccessionWindowAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CappedAccessionWindow) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedAccessionWindowAdjuster = steps[index]
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

        func evaluateAll(_ items: [CappedAccessionWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCappedAccessionWindowEngine() -> CappedAccessionWindowEngine {
        return CappedAccessionWindowEngine(
            steps: [
                PercentCappedAccessionWindowAdjuster(percent: -13.7),
                RoundingCappedAccessionWindowAdjuster(step: 0.1),
                MinimumCappedAccessionWindowAdjuster(minimum: 8.7),
                CapCappedAccessionWindowAdjuster(cap: 7786.0),
                CappedAccessionWindowDosageMgOffsetAdjuster(weight: 0.48),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 21302.6
        )
    }
}
