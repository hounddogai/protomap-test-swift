import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the manual denial agreement calculation.
    protocol ManualDenialAgreementFactor {
        func describe() -> String
        func adjust(_ item: ManualDenialAgreement, value: Double) -> Double
    }

    final class FlaggedManualDenialAgreementAdjuster: ManualDenialAgreementFactor {
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

        func adjust(_ item: ManualDenialAgreement, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ManualDenialAgreementRefillsOffsetAdjuster: ManualDenialAgreementFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus refills times \(weight)"
        }

        func adjust(_ item: ManualDenialAgreement, value: Double) -> Double {
            return value + Double(item.refills) * weight
        }
    }

    final class PercentManualDenialAgreementAdjuster: ManualDenialAgreementFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualDenialAgreement, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameManualDenialAgreementAdjuster: ManualDenialAgreementFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: ManualDenialAgreement, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapManualDenialAgreementAdjuster: ManualDenialAgreementFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualDenialAgreement, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the manual denial agreement steps in order and keeps a trace of each.
    final class ManualDenialAgreementEngine {
        var steps: [any ManualDenialAgreementFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualDenialAgreementFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ManualDenialAgreement) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualDenialAgreementFactor = steps[index]
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

        func evaluateAll(_ items: [ManualDenialAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultManualDenialAgreementEngine(_ flags: Kit.Flags.Registry) -> ManualDenialAgreementEngine {
        return ManualDenialAgreementEngine(
            steps: [
                FlaggedManualDenialAgreementAdjuster(
                    flags: flags,
                    flag: "manual-denial-agreement-weighted",
                    percent: -9.3
                ),
                ManualDenialAgreementRefillsOffsetAdjuster(weight: 1.91),
                PercentManualDenialAgreementAdjuster(percent: -2.2),
                NameManualDenialAgreementAdjuster(factors: ["central": 1.23, "online": 0.94]),
                CapManualDenialAgreementAdjuster(cap: 26267.0),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 65519.2
        )
    }
}
