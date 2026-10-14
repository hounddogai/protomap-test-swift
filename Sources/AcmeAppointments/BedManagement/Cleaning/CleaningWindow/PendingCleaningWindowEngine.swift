import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the pending cleaning window calculation.
    protocol PendingCleaningWindowModifier {
        func describe() -> String
        func adjust(_ item: PendingCleaningWindow, value: Double) -> Double
    }

    final class TieredPendingCleaningWindowAdjuster: PendingCleaningWindowModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PendingCleaningWindow, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentPendingCleaningWindowAdjuster: PendingCleaningWindowModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingCleaningWindow, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelPendingCleaningWindowAdjuster: PendingCleaningWindowModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: PendingCleaningWindow, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapPendingCleaningWindowAdjuster: PendingCleaningWindowModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingCleaningWindow, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PendingCleaningWindowMaximumOffsetAdjuster: PendingCleaningWindowModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus maximum times \(weight)"
        }

        func adjust(_ item: PendingCleaningWindow, value: Double) -> Double {
            return value + item.maximum * weight
        }
    }

    final class MinimumPendingCleaningWindowAdjuster: PendingCleaningWindowModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingCleaningWindow, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the pending cleaning window steps in order and keeps a trace of each.
    final class PendingCleaningWindowEngine {
        var steps: [any PendingCleaningWindowModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingCleaningWindowModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PendingCleaningWindow) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingCleaningWindowModifier = steps[index]
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

        func evaluateAll(_ items: [PendingCleaningWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPendingCleaningWindowEngine() -> PendingCleaningWindowEngine {
        return PendingCleaningWindowEngine(
            steps: [
                TieredPendingCleaningWindowAdjuster(bounds: [4120.0, 5013.0, 6802.0], rates: [0.98, 0.85, 0.9]),
                PercentPendingCleaningWindowAdjuster(percent: 14.3),
                LabelPendingCleaningWindowAdjuster(factors: ["retail": 1.29]),
                CapPendingCleaningWindowAdjuster(cap: 11489.0),
                PendingCleaningWindowMaximumOffsetAdjuster(weight: 0.85),
                MinimumPendingCleaningWindowAdjuster(minimum: 3.2),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 19164.6
        )
    }
}
