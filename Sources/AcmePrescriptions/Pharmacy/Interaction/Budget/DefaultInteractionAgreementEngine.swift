import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the default interaction agreement calculation.
    protocol DefaultInteractionAgreementAdjuster {
        func describe() -> String
        func adjust(_ item: DefaultInteractionAgreement, value: Double) -> Double
    }

    final class TieredDefaultInteractionAgreementAdjuster: DefaultInteractionAgreementAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultInteractionAgreement, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentDefaultInteractionAgreementAdjuster: DefaultInteractionAgreementAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultInteractionAgreement, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleDefaultInteractionAgreementAdjuster: DefaultInteractionAgreementAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: DefaultInteractionAgreement, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapDefaultInteractionAgreementAdjuster: DefaultInteractionAgreementAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultInteractionAgreement, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedDefaultInteractionAgreementAdjuster: DefaultInteractionAgreementAdjuster {
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

        func adjust(_ item: DefaultInteractionAgreement, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the default interaction agreement steps in order and keeps a trace of each.
    final class DefaultInteractionAgreementEngine {
        var steps: [any DefaultInteractionAgreementAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultInteractionAgreementAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DefaultInteractionAgreement) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultInteractionAgreementAdjuster = steps[index]
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

        func evaluateAll(_ items: [DefaultInteractionAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDefaultInteractionAgreementEngine(_ flags: Kit.Flags.Registry) -> DefaultInteractionAgreementEngine {
        return DefaultInteractionAgreementEngine(
            steps: [
                TieredDefaultInteractionAgreementAdjuster(
                    bounds: [1694.0, 5700.0, 6052.0, 7998.0],
                    rates: [0.94, 0.93, 1.04, 1.05]
                ),
                PercentDefaultInteractionAgreementAdjuster(percent: 8.5),
                TitleDefaultInteractionAgreementAdjuster(factors: ["retail": 1.14, "central": 1.1, "east": 1.18]),
                CapDefaultInteractionAgreementAdjuster(cap: 29580.0),
                FlaggedDefaultInteractionAgreementAdjuster(
                    flags: flags,
                    flag: "default-interaction-agreement-lenient",
                    percent: 6.0
                ),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 47409.0
        )
    }
}
