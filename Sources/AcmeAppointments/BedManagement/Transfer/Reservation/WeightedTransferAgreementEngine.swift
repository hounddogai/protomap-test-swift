import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the weighted transfer agreement calculation.
    protocol WeightedTransferAgreementStep {
        func describe() -> String
        func adjust(_ item: WeightedTransferAgreement, value: Double) -> Double
    }

    final class PercentWeightedTransferAgreementAdjuster: WeightedTransferAgreementStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedTransferAgreement, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ChannelWeightedTransferAgreementAdjuster: WeightedTransferAgreementStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: WeightedTransferAgreement, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredWeightedTransferAgreementAdjuster: WeightedTransferAgreementStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedTransferAgreement, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedWeightedTransferAgreementAdjuster: WeightedTransferAgreementStep {
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

        func adjust(_ item: WeightedTransferAgreement, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumWeightedTransferAgreementAdjuster: WeightedTransferAgreementStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedTransferAgreement, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class WeightedTransferAgreementThresholdOffsetAdjuster: WeightedTransferAgreementStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus threshold times \(weight)"
        }

        func adjust(_ item: WeightedTransferAgreement, value: Double) -> Double {
            return value + item.threshold * weight
        }
    }

    /// Runs the weighted transfer agreement steps in order and keeps a trace of each.
    final class WeightedTransferAgreementEngine {
        var steps: [any WeightedTransferAgreementStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedTransferAgreementStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: WeightedTransferAgreement) -> Double {
            var current = item.weightedExposure()
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

        func evaluateAll(_ items: [WeightedTransferAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultWeightedTransferAgreementEngine(_ flags: Kit.Flags.Registry) -> WeightedTransferAgreementEngine {
        return WeightedTransferAgreementEngine(
            steps: [
                PercentWeightedTransferAgreementAdjuster(percent: -11.5),
                ChannelWeightedTransferAgreementAdjuster(factors: ["north": 0.78, "online": 0.88]),
                TieredWeightedTransferAgreementAdjuster(bounds: [464.0, 8305.0], rates: [0.95, 1.05]),
                FlaggedWeightedTransferAgreementAdjuster(
                    flags: flags,
                    flag: "weighted-transfer-agreement-capped",
                    percent: 0.3
                ),
                MinimumWeightedTransferAgreementAdjuster(minimum: 18.8),
                WeightedTransferAgreementThresholdOffsetAdjuster(weight: 0.87),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 56327.8
        )
    }
}
