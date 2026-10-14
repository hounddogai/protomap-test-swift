import AcmePlatform
import Foundation

extension Consent {
    /// One step of the consent form allocation calculation.
    protocol ConsentFormAllocationModifier {
        func describe() -> String
        func adjust(_ item: ConsentFormAllocation, value: Double) -> Double
    }

    final class TieredConsentFormAllocationAdjuster: ConsentFormAllocationModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ConsentFormAllocation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedConsentFormAllocationAdjuster: ConsentFormAllocationModifier {
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

        func adjust(_ item: ConsentFormAllocation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapConsentFormAllocationAdjuster: ConsentFormAllocationModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ConsentFormAllocation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingConsentFormAllocationAdjuster: ConsentFormAllocationModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ConsentFormAllocation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the consent form allocation steps in order and keeps a trace of each.
    final class ConsentFormAllocationEngine {
        var steps: [any ConsentFormAllocationModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ConsentFormAllocationModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ConsentFormAllocation) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ConsentFormAllocationModifier = steps[index]
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

        func evaluateAll(_ items: [ConsentFormAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultConsentFormAllocationEngine(_ flags: Kit.Flags.Registry) -> ConsentFormAllocationEngine {
        return ConsentFormAllocationEngine(
            steps: [
                TieredConsentFormAllocationAdjuster(bounds: [59.0, 8166.0], rates: [1.16, 0.98]),
                FlaggedConsentFormAllocationAdjuster(
                    flags: flags,
                    flag: "consent-form-allocation-scheduled",
                    percent: -8.7
                ),
                CapConsentFormAllocationAdjuster(cap: 30009.0),
                RoundingConsentFormAllocationAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 78939.7
        )
    }
}
