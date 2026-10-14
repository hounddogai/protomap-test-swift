import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the handoff bundle calculation.
    protocol HandoffBundleAdjuster {
        func describe() -> String
        func adjust(_ item: HandoffBundle, value: Double) -> Double
    }

    final class CapHandoffBundleAdjuster: HandoffBundleAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: HandoffBundle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredHandoffBundleAdjuster: HandoffBundleAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: HandoffBundle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingHandoffBundleAdjuster: HandoffBundleAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: HandoffBundle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentHandoffBundleAdjuster: HandoffBundleAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: HandoffBundle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class HandoffBundleMaximumOffsetAdjuster: HandoffBundleAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus maximum times \(weight)"
        }

        func adjust(_ item: HandoffBundle, value: Double) -> Double {
            return value + item.maximum * weight
        }
    }

    /// Runs the handoff bundle steps in order and keeps a trace of each.
    final class HandoffBundleEngine {
        var steps: [any HandoffBundleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any HandoffBundleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: HandoffBundle) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any HandoffBundleAdjuster = steps[index]
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

        func evaluateAll(_ items: [HandoffBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultHandoffBundleEngine() -> HandoffBundleEngine {
        return HandoffBundleEngine(
            steps: [
                CapHandoffBundleAdjuster(cap: 29884.0),
                TieredHandoffBundleAdjuster(bounds: [645.0, 4076.0, 8763.0], rates: [1.18, 1.16, 1.08]),
                RoundingHandoffBundleAdjuster(step: 0.25),
                PercentHandoffBundleAdjuster(percent: 12.0),
                HandoffBundleMaximumOffsetAdjuster(weight: 1.8),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 26852.8
        )
    }
}
