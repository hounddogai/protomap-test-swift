import AcmePlatform
import Foundation

extension Labs {
    /// One step of the default specimen policy calculation.
    protocol DefaultSpecimenPolicyModifier {
        func describe() -> String
        func adjust(_ item: DefaultSpecimenPolicy, value: Double) -> Double
    }

    final class FlaggedDefaultSpecimenPolicyAdjuster: DefaultSpecimenPolicyModifier {
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

        func adjust(_ item: DefaultSpecimenPolicy, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class DefaultSpecimenPolicyWindowDaysOffsetAdjuster: DefaultSpecimenPolicyModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: DefaultSpecimenPolicy, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    final class NameDefaultSpecimenPolicyAdjuster: DefaultSpecimenPolicyModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: DefaultSpecimenPolicy, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingDefaultSpecimenPolicyAdjuster: DefaultSpecimenPolicyModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultSpecimenPolicy, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredDefaultSpecimenPolicyAdjuster: DefaultSpecimenPolicyModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultSpecimenPolicy, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the default specimen policy steps in order and keeps a trace of each.
    final class DefaultSpecimenPolicyEngine {
        var steps: [any DefaultSpecimenPolicyModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultSpecimenPolicyModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: DefaultSpecimenPolicy) -> Double {
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

        func evaluateAll(_ items: [DefaultSpecimenPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultDefaultSpecimenPolicyEngine(_ flags: Kit.Flags.Registry) -> DefaultSpecimenPolicyEngine {
        return DefaultSpecimenPolicyEngine(
            steps: [
                FlaggedDefaultSpecimenPolicyAdjuster(
                    flags: flags,
                    flag: "default-specimen-policy-scheduled",
                    percent: 2.5
                ),
                DefaultSpecimenPolicyWindowDaysOffsetAdjuster(weight: 1.0),
                NameDefaultSpecimenPolicyAdjuster(factors: ["north": 1.24, "west": 1.34]),
                RoundingDefaultSpecimenPolicyAdjuster(step: 0.1),
                TieredDefaultSpecimenPolicyAdjuster(
                    bounds: [3675.0, 6425.0, 7927.0, 8020.0],
                    rates: [1.05, 0.87, 0.82, 1.07]
                ),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 43153.6
        )
    }
}
