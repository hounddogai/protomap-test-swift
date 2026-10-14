import AcmePlatform
import Foundation

extension Labs {
    /// One step of the specimen agreement calculation.
    protocol SpecimenAgreementAdjuster {
        func describe() -> String
        func adjust(_ item: SpecimenAgreement, value: Double) -> Double
    }

    final class FlaggedSpecimenAgreementAdjuster: SpecimenAgreementAdjuster {
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

        func adjust(_ item: SpecimenAgreement, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelSpecimenAgreementAdjuster: SpecimenAgreementAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: SpecimenAgreement, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumSpecimenAgreementAdjuster: SpecimenAgreementAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SpecimenAgreement, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentSpecimenAgreementAdjuster: SpecimenAgreementAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SpecimenAgreement, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the specimen agreement steps in order and keeps a trace of each.
    final class SpecimenAgreementEngine {
        var steps: [any SpecimenAgreementAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SpecimenAgreementAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SpecimenAgreement) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [SpecimenAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSpecimenAgreementEngine(_ flags: Kit.Flags.Registry) -> SpecimenAgreementEngine {
        return SpecimenAgreementEngine(
            steps: [
                FlaggedSpecimenAgreementAdjuster(flags: flags, flag: "specimen-agreement-weighted", percent: 7.2),
                LabelSpecimenAgreementAdjuster(factors: ["south": 1.19]),
                MinimumSpecimenAgreementAdjuster(minimum: 46.5),
                PercentSpecimenAgreementAdjuster(percent: 6.2),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 74119.4
        )
    }
}
