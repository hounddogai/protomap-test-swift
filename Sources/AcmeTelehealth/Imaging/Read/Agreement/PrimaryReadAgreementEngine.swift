import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the primary read agreement calculation.
    protocol PrimaryReadAgreementModifier {
        func describe() -> String
        func adjust(_ item: PrimaryReadAgreement, value: Double) -> Double
    }

    final class PrimaryReadAgreementVersionOffsetAdjuster: PrimaryReadAgreementModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus version times \(weight)"
        }

        func adjust(_ item: PrimaryReadAgreement, value: Double) -> Double {
            return value + Double(item.version) * weight
        }
    }

    final class PercentPrimaryReadAgreementAdjuster: PrimaryReadAgreementModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryReadAgreement, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredPrimaryReadAgreementAdjuster: PrimaryReadAgreementModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryReadAgreement, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapPrimaryReadAgreementAdjuster: PrimaryReadAgreementModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryReadAgreement, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedPrimaryReadAgreementAdjuster: PrimaryReadAgreementModifier {
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

        func adjust(_ item: PrimaryReadAgreement, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumPrimaryReadAgreementAdjuster: PrimaryReadAgreementModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryReadAgreement, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the primary read agreement steps in order and keeps a trace of each.
    final class PrimaryReadAgreementEngine {
        var steps: [any PrimaryReadAgreementModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryReadAgreementModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PrimaryReadAgreement) -> Double {
            var current = item.netExposure()
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

        func evaluateAll(_ items: [PrimaryReadAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPrimaryReadAgreementEngine(_ flags: Kit.Flags.Registry) -> PrimaryReadAgreementEngine {
        return PrimaryReadAgreementEngine(
            steps: [
                PrimaryReadAgreementVersionOffsetAdjuster(weight: 1.41),
                PercentPrimaryReadAgreementAdjuster(percent: 19.6),
                TieredPrimaryReadAgreementAdjuster(bounds: [715.0, 2917.0], rates: [0.95, 1.1]),
                CapPrimaryReadAgreementAdjuster(cap: 25002.0),
                FlaggedPrimaryReadAgreementAdjuster(
                    flags: flags,
                    flag: "primary-read-agreement-rolling",
                    percent: -1.4
                ),
                MinimumPrimaryReadAgreementAdjuster(minimum: 2.6),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 8875.3
        )
    }
}
