import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the manual handoff target calculation.
    protocol ManualHandoffTargetModifier {
        func describe() -> String
        func adjust(_ item: ManualHandoffTarget, value: Double) -> Double
    }

    final class PercentManualHandoffTargetAdjuster: ManualHandoffTargetModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualHandoffTarget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ChannelManualHandoffTargetAdjuster: ManualHandoffTargetModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: ManualHandoffTarget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedManualHandoffTargetAdjuster: ManualHandoffTargetModifier {
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

        func adjust(_ item: ManualHandoffTarget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ManualHandoffTargetWeightOffsetAdjuster: ManualHandoffTargetModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus weight times \(weight)"
        }

        func adjust(_ item: ManualHandoffTarget, value: Double) -> Double {
            return value + item.weight * weight
        }
    }

    final class TieredManualHandoffTargetAdjuster: ManualHandoffTargetModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualHandoffTarget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapManualHandoffTargetAdjuster: ManualHandoffTargetModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualHandoffTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the manual handoff target steps in order and keeps a trace of each.
    final class ManualHandoffTargetEngine {
        var steps: [any ManualHandoffTargetModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualHandoffTargetModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ManualHandoffTarget) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualHandoffTargetModifier = steps[index]
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

        func evaluateAll(_ items: [ManualHandoffTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultManualHandoffTargetEngine(_ flags: Kit.Flags.Registry) -> ManualHandoffTargetEngine {
        return ManualHandoffTargetEngine(
            steps: [
                PercentManualHandoffTargetAdjuster(percent: 14.0),
                ChannelManualHandoffTargetAdjuster(factors: ["north": 1.16]),
                FlaggedManualHandoffTargetAdjuster(flags: flags, flag: "manual-handoff-target-seasonal", percent: 5.2),
                ManualHandoffTargetWeightOffsetAdjuster(weight: 0.61),
                TieredManualHandoffTargetAdjuster(
                    bounds: [563.0, 1295.0, 1893.0, 3635.0],
                    rates: [0.84, 1.08, 1.14, 0.92]
                ),
                CapManualHandoffTargetAdjuster(cap: 6349.0),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 31397.2
        )
    }
}
