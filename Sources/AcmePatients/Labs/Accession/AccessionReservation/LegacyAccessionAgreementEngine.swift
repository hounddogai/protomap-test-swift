import AcmePlatform
import Foundation

extension Labs {
    /// One step of the legacy accession agreement calculation.
    protocol LegacyAccessionAgreementAdjuster {
        func describe() -> String
        func adjust(_ item: LegacyAccessionAgreement, value: Double) -> Double
    }

    final class FlaggedLegacyAccessionAgreementAdjuster: LegacyAccessionAgreementAdjuster {
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

        func adjust(_ item: LegacyAccessionAgreement, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredLegacyAccessionAgreementAdjuster: LegacyAccessionAgreementAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyAccessionAgreement, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumLegacyAccessionAgreementAdjuster: LegacyAccessionAgreementAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyAccessionAgreement, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentLegacyAccessionAgreementAdjuster: LegacyAccessionAgreementAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LegacyAccessionAgreement, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LegacyAccessionAgreementAmountOffsetAdjuster: LegacyAccessionAgreementAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: LegacyAccessionAgreement, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class LabelLegacyAccessionAgreementAdjuster: LegacyAccessionAgreementAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: LegacyAccessionAgreement, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the legacy accession agreement steps in order and keeps a trace of each.
    final class LegacyAccessionAgreementEngine {
        var steps: [any LegacyAccessionAgreementAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyAccessionAgreementAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LegacyAccessionAgreement) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacyAccessionAgreementAdjuster = steps[index]
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

        func evaluateAll(_ items: [LegacyAccessionAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLegacyAccessionAgreementEngine(_ flags: Kit.Flags.Registry) -> LegacyAccessionAgreementEngine {
        return LegacyAccessionAgreementEngine(
            steps: [
                FlaggedLegacyAccessionAgreementAdjuster(
                    flags: flags,
                    flag: "legacy-accession-agreement-rolling",
                    percent: -1.6
                ),
                TieredLegacyAccessionAgreementAdjuster(
                    bounds: [2926.0, 3592.0, 4433.0, 5937.0],
                    rates: [1.19, 0.85, 0.87, 1.06]
                ),
                MinimumLegacyAccessionAgreementAdjuster(minimum: 16.8),
                PercentLegacyAccessionAgreementAdjuster(percent: -14.2),
                LegacyAccessionAgreementAmountOffsetAdjuster(weight: 1.15),
                LabelLegacyAccessionAgreementAdjuster(factors: ["central": 1.12, "north": 1.0, "south": 1.1]),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 60509.9
        )
    }
}
