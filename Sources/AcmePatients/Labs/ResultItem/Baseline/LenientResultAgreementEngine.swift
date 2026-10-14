import AcmePlatform
import Foundation

extension Labs {
    /// One step of the lenient result agreement calculation.
    protocol LenientResultAgreementAdjuster {
        func describe() -> String
        func adjust(_ item: LenientResultAgreement, value: Double) -> Double
    }

    final class LenientResultAgreementCreatedAtOffsetAdjuster: LenientResultAgreementAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus created at times \(weight)"
        }

        func adjust(_ item: LenientResultAgreement, value: Double) -> Double {
            return value + Double(item.createdAt) * weight
        }
    }

    final class PercentLenientResultAgreementAdjuster: LenientResultAgreementAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientResultAgreement, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumLenientResultAgreementAdjuster: LenientResultAgreementAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientResultAgreement, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TitleLenientResultAgreementAdjuster: LenientResultAgreementAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: LenientResultAgreement, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedLenientResultAgreementAdjuster: LenientResultAgreementAdjuster {
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

        func adjust(_ item: LenientResultAgreement, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapLenientResultAgreementAdjuster: LenientResultAgreementAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientResultAgreement, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the lenient result agreement steps in order and keeps a trace of each.
    final class LenientResultAgreementEngine {
        var steps: [any LenientResultAgreementAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientResultAgreementAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LenientResultAgreement) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientResultAgreementAdjuster = steps[index]
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

        func evaluateAll(_ items: [LenientResultAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLenientResultAgreementEngine(_ flags: Kit.Flags.Registry) -> LenientResultAgreementEngine {
        return LenientResultAgreementEngine(
            steps: [
                LenientResultAgreementCreatedAtOffsetAdjuster(weight: 0.17),
                PercentLenientResultAgreementAdjuster(percent: -8.1),
                MinimumLenientResultAgreementAdjuster(minimum: 13.0),
                TitleLenientResultAgreementAdjuster(factors: ["east": 1.34]),
                FlaggedLenientResultAgreementAdjuster(
                    flags: flags,
                    flag: "lenient-result-agreement-rolling",
                    percent: -3.6
                ),
                CapLenientResultAgreementAdjuster(cap: 31966.0),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 17930.7
        )
    }
}
