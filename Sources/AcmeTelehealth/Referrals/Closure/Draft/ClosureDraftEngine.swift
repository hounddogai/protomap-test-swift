import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the closure draft calculation.
    protocol ClosureDraftFactor {
        func describe() -> String
        func adjust(_ item: ClosureDraft, value: Double) -> Double
    }

    final class FlaggedClosureDraftAdjuster: ClosureDraftFactor {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: ClosureDraft, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredClosureDraftAdjuster: ClosureDraftFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ClosureDraft, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class ClosureDraftQuantityOffsetAdjuster: ClosureDraftFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: ClosureDraft, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class RoundingClosureDraftAdjuster: ClosureDraftFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ClosureDraft, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the closure draft steps in order and keeps a trace of each.
    final class ClosureDraftEngine {
        var steps: [any ClosureDraftFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClosureDraftFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ClosureDraft) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ClosureDraftFactor = steps[index]
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

        func evaluateAll(_ items: [ClosureDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultClosureDraftEngine(_ flags: Kit.Flags.Registry) -> ClosureDraftEngine {
        return ClosureDraftEngine(
            steps: [
                FlaggedClosureDraftAdjuster(flags: flags, flag: "closure-draft-global", percent: 0.6),
                TieredClosureDraftAdjuster(bounds: [724.0, 1112.0, 1565.0, 9173.0], rates: [0.99, 0.87, 1.15, 0.99]),
                ClosureDraftQuantityOffsetAdjuster(weight: 0.66),
                RoundingClosureDraftAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 63916.6
        )
    }
}
