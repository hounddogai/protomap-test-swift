import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the strict shift bundle calculation.
    protocol StrictShiftBundleAdjuster {
        func describe() -> String
        func adjust(_ item: StrictShiftBundle, value: Double) -> Double
    }

    final class PercentStrictShiftBundleAdjuster: StrictShiftBundleAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StrictShiftBundle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapStrictShiftBundleAdjuster: StrictShiftBundleAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StrictShiftBundle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class StrictShiftBundleExpiresAtOffsetAdjuster: StrictShiftBundleAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: StrictShiftBundle, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    final class WardStrictShiftBundleAdjuster: StrictShiftBundleAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: StrictShiftBundle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumStrictShiftBundleAdjuster: StrictShiftBundleAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictShiftBundle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the strict shift bundle steps in order and keeps a trace of each.
    final class StrictShiftBundleEngine {
        var steps: [any StrictShiftBundleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictShiftBundleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: StrictShiftBundle) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any StrictShiftBundleAdjuster = steps[index]
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

        func evaluateAll(_ items: [StrictShiftBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultStrictShiftBundleEngine() -> StrictShiftBundleEngine {
        return StrictShiftBundleEngine(
            steps: [
                PercentStrictShiftBundleAdjuster(percent: 21.8),
                CapStrictShiftBundleAdjuster(cap: 39313.0),
                StrictShiftBundleExpiresAtOffsetAdjuster(weight: 1.37),
                WardStrictShiftBundleAdjuster(factors: ["retail": 1.31, "central": 0.95]),
                MinimumStrictShiftBundleAdjuster(minimum: 23.9),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 30068.3
        )
    }
}
