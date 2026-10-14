import AcmePlatform
import Foundation

extension Consent {
    /// One step of the legacy disclosure agreement calculation.
    protocol LegacyDisclosureAgreementAdjuster {
        func describe() -> String
        func adjust(_ item: LegacyDisclosureAgreement, value: Double) -> Double
    }

    final class TieredLegacyDisclosureAgreementAdjuster: LegacyDisclosureAgreementAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyDisclosureAgreement, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingLegacyDisclosureAgreementAdjuster: LegacyDisclosureAgreementAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyDisclosureAgreement, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class LegacyDisclosureAgreementCreatedAtOffsetAdjuster: LegacyDisclosureAgreementAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus created at times \(weight)"
        }

        func adjust(_ item: LegacyDisclosureAgreement, value: Double) -> Double {
            return value + Double(item.createdAt) * weight
        }
    }

    final class SegmentLegacyDisclosureAgreementAdjuster: LegacyDisclosureAgreementAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: LegacyDisclosureAgreement, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedLegacyDisclosureAgreementAdjuster: LegacyDisclosureAgreementAdjuster {
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

        func adjust(_ item: LegacyDisclosureAgreement, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentLegacyDisclosureAgreementAdjuster: LegacyDisclosureAgreementAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LegacyDisclosureAgreement, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the legacy disclosure agreement steps in order and keeps a trace of each.
    final class LegacyDisclosureAgreementEngine {
        var steps: [any LegacyDisclosureAgreementAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyDisclosureAgreementAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LegacyDisclosureAgreement) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacyDisclosureAgreementAdjuster = steps[index]
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

        func evaluateAll(_ items: [LegacyDisclosureAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLegacyDisclosureAgreementEngine(_ flags: Kit.Flags.Registry) -> LegacyDisclosureAgreementEngine {
        return LegacyDisclosureAgreementEngine(
            steps: [
                TieredLegacyDisclosureAgreementAdjuster(bounds: [3265.0, 4743.0, 9976.0], rates: [1.03, 0.89, 0.91]),
                RoundingLegacyDisclosureAgreementAdjuster(step: 0.25),
                LegacyDisclosureAgreementCreatedAtOffsetAdjuster(weight: 1.27),
                SegmentLegacyDisclosureAgreementAdjuster(factors: ["central": 1.0]),
                FlaggedLegacyDisclosureAgreementAdjuster(
                    flags: flags,
                    flag: "legacy-disclosure-agreement-regional",
                    percent: -4.2
                ),
                PercentLegacyDisclosureAgreementAdjuster(percent: 9.4),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 47413.6
        )
    }
}
