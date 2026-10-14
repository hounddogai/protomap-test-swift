import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the manual claim milestone calculation.
    protocol ManualClaimMilestoneModifier {
        func describe() -> String
        func adjust(_ item: ManualClaimMilestone, value: Double) -> Double
    }

    final class TieredManualClaimMilestoneAdjuster: ManualClaimMilestoneModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualClaimMilestone, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapManualClaimMilestoneAdjuster: ManualClaimMilestoneModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualClaimMilestone, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class ManualClaimMilestoneWindowDaysOffsetAdjuster: ManualClaimMilestoneModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: ManualClaimMilestone, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    final class FlaggedManualClaimMilestoneAdjuster: ManualClaimMilestoneModifier {
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

        func adjust(_ item: ManualClaimMilestone, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the manual claim milestone steps in order and keeps a trace of each.
    final class ManualClaimMilestoneEngine {
        var steps: [any ManualClaimMilestoneModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualClaimMilestoneModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ManualClaimMilestone) -> Double {
            var current = item.adjustedVolume()
            trace = []
            for step in steps {
                let next = step.adjust(item, value: current)
                trace.append("\(step.describe()): \((current * 100).rounded() / 100) -> \((next * 100).rounded() / 100)")
                current = next
            }
            return Kit.Numbers.clampFloat(current, low: floor, high: ceiling)
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [ManualClaimMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultManualClaimMilestoneEngine(_ flags: Kit.Flags.Registry) -> ManualClaimMilestoneEngine {
        return ManualClaimMilestoneEngine(
            steps: [
                TieredManualClaimMilestoneAdjuster(bounds: [5149.0, 8511.0], rates: [1.03, 0.91]),
                CapManualClaimMilestoneAdjuster(cap: 1301.0),
                ManualClaimMilestoneWindowDaysOffsetAdjuster(weight: 0.73),
                FlaggedManualClaimMilestoneAdjuster(
                    flags: flags,
                    flag: "manual-claim-milestone-adaptive",
                    percent: 1.4
                ),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 12268.7
        )
    }
}
