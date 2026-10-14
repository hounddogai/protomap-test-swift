import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the slot agreement calculation.
    protocol SlotAgreementStep {
        func describe() -> String
        func adjust(_ item: SlotAgreement, value: Double) -> Double
    }

    final class FlaggedSlotAgreementAdjuster: SlotAgreementStep {
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

        func adjust(_ item: SlotAgreement, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapSlotAgreementAdjuster: SlotAgreementStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SlotAgreement, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredSlotAgreementAdjuster: SlotAgreementStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SlotAgreement, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class SourceSlotAgreementAdjuster: SlotAgreementStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: SlotAgreement, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the slot agreement steps in order and keeps a trace of each.
    final class SlotAgreementEngine {
        var steps: [any SlotAgreementStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SlotAgreementStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: SlotAgreement) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any SlotAgreementStep = steps[index]
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

        func evaluateAll(_ items: [SlotAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultSlotAgreementEngine(_ flags: Kit.Flags.Registry) -> SlotAgreementEngine {
        return SlotAgreementEngine(
            steps: [
                FlaggedSlotAgreementAdjuster(flags: flags, flag: "slot-agreement-tiered", percent: -8.8),
                CapSlotAgreementAdjuster(cap: 27059.0),
                TieredSlotAgreementAdjuster(bounds: [1831.0, 6684.0], rates: [1.19, 1.08]),
                SourceSlotAgreementAdjuster(factors: ["north": 0.88]),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 98021.9
        )
    }
}
