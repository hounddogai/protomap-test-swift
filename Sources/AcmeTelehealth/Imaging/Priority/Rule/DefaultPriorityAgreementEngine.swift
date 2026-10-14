import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the default priority agreement calculation.
    protocol DefaultPriorityAgreementStep {
        func describe() -> String
        func adjust(_ item: DefaultPriorityAgreement, value: Double) -> Double
    }

    final class DefaultPriorityAgreementCeilingOffsetAdjuster: DefaultPriorityAgreementStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ceiling times \(weight)"
        }

        func adjust(_ item: DefaultPriorityAgreement, value: Double) -> Double {
            return value + item.ceiling * weight
        }
    }

    final class FlaggedDefaultPriorityAgreementAdjuster: DefaultPriorityAgreementStep {
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

        func adjust(_ item: DefaultPriorityAgreement, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredDefaultPriorityAgreementAdjuster: DefaultPriorityAgreementStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultPriorityAgreement, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapDefaultPriorityAgreementAdjuster: DefaultPriorityAgreementStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultPriorityAgreement, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the default priority agreement steps in order and keeps a trace of each.
    final class DefaultPriorityAgreementEngine {
        var steps: [any DefaultPriorityAgreementStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultPriorityAgreementStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DefaultPriorityAgreement) -> Double {
            var current = item.effectiveTotal()
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

        func evaluateAll(_ items: [DefaultPriorityAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDefaultPriorityAgreementEngine(_ flags: Kit.Flags.Registry) -> DefaultPriorityAgreementEngine {
        return DefaultPriorityAgreementEngine(
            steps: [
                DefaultPriorityAgreementCeilingOffsetAdjuster(weight: 1.48),
                FlaggedDefaultPriorityAgreementAdjuster(
                    flags: flags,
                    flag: "default-priority-agreement-adaptive",
                    percent: 0.9
                ),
                TieredDefaultPriorityAgreementAdjuster(bounds: [2214.0, 4378.0, 8627.0], rates: [0.98, 0.81, 1.01]),
                CapDefaultPriorityAgreementAdjuster(cap: 24394.0),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 28495.4
        )
    }
}
