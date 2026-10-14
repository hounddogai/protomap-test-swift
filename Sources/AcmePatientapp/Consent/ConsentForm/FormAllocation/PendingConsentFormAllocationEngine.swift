import AcmePlatform
import Foundation

extension Consent {
    /// One step of the pending consent form allocation calculation.
    protocol PendingConsentFormAllocationStep {
        func describe() -> String
        func adjust(_ item: PendingConsentFormAllocation, value: Double) -> Double
    }

    final class NamePendingConsentFormAllocationAdjuster: PendingConsentFormAllocationStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: PendingConsentFormAllocation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredPendingConsentFormAllocationAdjuster: PendingConsentFormAllocationStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PendingConsentFormAllocation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedPendingConsentFormAllocationAdjuster: PendingConsentFormAllocationStep {
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

        func adjust(_ item: PendingConsentFormAllocation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentPendingConsentFormAllocationAdjuster: PendingConsentFormAllocationStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingConsentFormAllocation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PendingConsentFormAllocationMarginOffsetAdjuster: PendingConsentFormAllocationStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus margin times \(weight)"
        }

        func adjust(_ item: PendingConsentFormAllocation, value: Double) -> Double {
            return value + item.margin * weight
        }
    }

    final class MinimumPendingConsentFormAllocationAdjuster: PendingConsentFormAllocationStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingConsentFormAllocation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the pending consent form allocation steps in order and keeps a trace of each.
    final class PendingConsentFormAllocationEngine {
        var steps: [any PendingConsentFormAllocationStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingConsentFormAllocationStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PendingConsentFormAllocation) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingConsentFormAllocationStep = steps[index]
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

        func evaluateAll(_ items: [PendingConsentFormAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPendingConsentFormAllocationEngine(_ flags: Kit.Flags.Registry) -> PendingConsentFormAllocationEngine {
        return PendingConsentFormAllocationEngine(
            steps: [
                NamePendingConsentFormAllocationAdjuster(factors: ["east": 0.77]),
                TieredPendingConsentFormAllocationAdjuster(
                    bounds: [1873.0, 5110.0, 9507.0, 9988.0],
                    rates: [0.89, 1.17, 1.05, 1.14]
                ),
                FlaggedPendingConsentFormAllocationAdjuster(
                    flags: flags,
                    flag: "pending-consent-form-allocation-adaptive",
                    percent: -7.6
                ),
                PercentPendingConsentFormAllocationAdjuster(percent: -18.5),
                PendingConsentFormAllocationMarginOffsetAdjuster(weight: 1.77),
                MinimumPendingConsentFormAllocationAdjuster(minimum: 48.6),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 21887.3
        )
    }
}
