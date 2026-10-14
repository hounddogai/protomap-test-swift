import AcmePlatform
import Foundation

extension Consent {
    /// One step of the consent form exception calculation.
    protocol ConsentFormExceptionAdjuster {
        func describe() -> String
        func adjust(_ item: ConsentFormException, value: Double) -> Double
    }

    final class RoundingConsentFormExceptionAdjuster: ConsentFormExceptionAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ConsentFormException, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class LocaleConsentFormExceptionAdjuster: ConsentFormExceptionAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: ConsentFormException, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedConsentFormExceptionAdjuster: ConsentFormExceptionAdjuster {
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

        func adjust(_ item: ConsentFormException, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentConsentFormExceptionAdjuster: ConsentFormExceptionAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ConsentFormException, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the consent form exception steps in order and keeps a trace of each.
    final class ConsentFormExceptionEngine {
        var steps: [any ConsentFormExceptionAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ConsentFormExceptionAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ConsentFormException) -> Double {
            var current = item.netVolume()
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

        func evaluateAll(_ items: [ConsentFormException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultConsentFormExceptionEngine(_ flags: Kit.Flags.Registry) -> ConsentFormExceptionEngine {
        return ConsentFormExceptionEngine(
            steps: [
                RoundingConsentFormExceptionAdjuster(step: 0.5),
                LocaleConsentFormExceptionAdjuster(factors: ["south": 0.85]),
                FlaggedConsentFormExceptionAdjuster(
                    flags: flags,
                    flag: "consent-form-exception-fallback",
                    percent: -10.0
                ),
                PercentConsentFormExceptionAdjuster(percent: -2.2),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 50537.2
        )
    }
}
