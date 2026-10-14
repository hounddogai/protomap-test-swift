import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the fallback worklist agreement calculation.
    protocol FallbackWorklistAgreementAdjuster {
        func describe() -> String
        func adjust(_ item: FallbackWorklistAgreement, value: Double) -> Double
    }

    final class RoundingFallbackWorklistAgreementAdjuster: FallbackWorklistAgreementAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackWorklistAgreement, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentFallbackWorklistAgreementAdjuster: FallbackWorklistAgreementAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackWorklistAgreement, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleFallbackWorklistAgreementAdjuster: FallbackWorklistAgreementAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: FallbackWorklistAgreement, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedFallbackWorklistAgreementAdjuster: FallbackWorklistAgreementAdjuster {
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

        func adjust(_ item: FallbackWorklistAgreement, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FallbackWorklistAgreementMinimumOffsetAdjuster: FallbackWorklistAgreementAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: FallbackWorklistAgreement, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    /// Runs the fallback worklist agreement steps in order and keeps a trace of each.
    final class FallbackWorklistAgreementEngine {
        var steps: [any FallbackWorklistAgreementAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackWorklistAgreementAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: FallbackWorklistAgreement) -> Double {
            var current = item.weightedLoad()
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

        func evaluateAll(_ items: [FallbackWorklistAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultFallbackWorklistAgreementEngine(_ flags: Kit.Flags.Registry) -> FallbackWorklistAgreementEngine {
        return FallbackWorklistAgreementEngine(
            steps: [
                RoundingFallbackWorklistAgreementAdjuster(step: 1.0),
                PercentFallbackWorklistAgreementAdjuster(percent: 17.6),
                TitleFallbackWorklistAgreementAdjuster(factors: ["south": 0.92]),
                FlaggedFallbackWorklistAgreementAdjuster(
                    flags: flags,
                    flag: "fallback-worklist-agreement-batched",
                    percent: -6.4
                ),
                FallbackWorklistAgreementMinimumOffsetAdjuster(weight: 1.72),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 62279.0
        )
    }
}
