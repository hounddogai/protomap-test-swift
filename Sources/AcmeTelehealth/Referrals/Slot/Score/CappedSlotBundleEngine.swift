import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the capped slot bundle calculation.
    protocol CappedSlotBundleAdjuster {
        func describe() -> String
        func adjust(_ item: CappedSlotBundle, value: Double) -> Double
    }

    final class CapCappedSlotBundleAdjuster: CappedSlotBundleAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedSlotBundle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class NameCappedSlotBundleAdjuster: CappedSlotBundleAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: CappedSlotBundle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredCappedSlotBundleAdjuster: CappedSlotBundleAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedSlotBundle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumCappedSlotBundleAdjuster: CappedSlotBundleAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedSlotBundle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentCappedSlotBundleAdjuster: CappedSlotBundleAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedSlotBundle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the capped slot bundle steps in order and keeps a trace of each.
    final class CappedSlotBundleEngine {
        var steps: [any CappedSlotBundleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedSlotBundleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CappedSlotBundle) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedSlotBundleAdjuster = steps[index]
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

        func evaluateAll(_ items: [CappedSlotBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCappedSlotBundleEngine() -> CappedSlotBundleEngine {
        return CappedSlotBundleEngine(
            steps: [
                CapCappedSlotBundleAdjuster(cap: 25303.0),
                NameCappedSlotBundleAdjuster(factors: ["east": 0.89, "retail": 1.02]),
                TieredCappedSlotBundleAdjuster(bounds: [1196.0, 1606.0, 4154.0], rates: [1.03, 1.09, 1.0]),
                MinimumCappedSlotBundleAdjuster(minimum: 46.6),
                PercentCappedSlotBundleAdjuster(percent: -1.6),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 74367.0
        )
    }
}
