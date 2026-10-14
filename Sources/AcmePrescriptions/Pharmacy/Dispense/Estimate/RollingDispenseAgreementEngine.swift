import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the rolling dispense agreement calculation.
    protocol RollingDispenseAgreementModifier {
        func describe() -> String
        func adjust(_ item: RollingDispenseAgreement, value: Double) -> Double
    }

    final class TieredRollingDispenseAgreementAdjuster: RollingDispenseAgreementModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingDispenseAgreement, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumRollingDispenseAgreementAdjuster: RollingDispenseAgreementModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingDispenseAgreement, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedRollingDispenseAgreementAdjuster: RollingDispenseAgreementModifier {
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

        func adjust(_ item: RollingDispenseAgreement, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingRollingDispenseAgreementAdjuster: RollingDispenseAgreementModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingDispenseAgreement, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class RollingDispenseAgreementLimitOffsetAdjuster: RollingDispenseAgreementModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus limit times \(weight)"
        }

        func adjust(_ item: RollingDispenseAgreement, value: Double) -> Double {
            return value + Double(item.limit) * weight
        }
    }

    /// Runs the rolling dispense agreement steps in order and keeps a trace of each.
    final class RollingDispenseAgreementEngine {
        var steps: [any RollingDispenseAgreementModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingDispenseAgreementModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RollingDispenseAgreement) -> Double {
            var current = item.projectedVolume()
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

        func evaluateAll(_ items: [RollingDispenseAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRollingDispenseAgreementEngine(_ flags: Kit.Flags.Registry) -> RollingDispenseAgreementEngine {
        return RollingDispenseAgreementEngine(
            steps: [
                TieredRollingDispenseAgreementAdjuster(
                    bounds: [395.0, 4169.0, 4478.0, 8420.0],
                    rates: [1.13, 1.05, 1.18, 0.99]
                ),
                MinimumRollingDispenseAgreementAdjuster(minimum: 40.1),
                FlaggedRollingDispenseAgreementAdjuster(
                    flags: flags,
                    flag: "rolling-dispense-agreement-adaptive",
                    percent: 8.7
                ),
                RoundingRollingDispenseAgreementAdjuster(step: 5.0),
                RollingDispenseAgreementLimitOffsetAdjuster(weight: 0.55),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 59141.3
        )
    }
}
