import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the regional statement profile calculation.
    protocol RegionalStatementProfileFactor {
        func describe() -> String
        func adjust(_ item: RegionalStatementProfile, value: Double) -> Double
    }

    final class RegionalStatementProfileAmountOffsetAdjuster: RegionalStatementProfileFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: RegionalStatementProfile, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class TitleRegionalStatementProfileAdjuster: RegionalStatementProfileFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: RegionalStatementProfile, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumRegionalStatementProfileAdjuster: RegionalStatementProfileFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalStatementProfile, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedRegionalStatementProfileAdjuster: RegionalStatementProfileFactor {
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

        func adjust(_ item: RegionalStatementProfile, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredRegionalStatementProfileAdjuster: RegionalStatementProfileFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalStatementProfile, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the regional statement profile steps in order and keeps a trace of each.
    final class RegionalStatementProfileEngine {
        var steps: [any RegionalStatementProfileFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalStatementProfileFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RegionalStatementProfile) -> Double {
            var current = item.adjustedTotal()
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

        func evaluateAll(_ items: [RegionalStatementProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRegionalStatementProfileEngine(_ flags: Kit.Flags.Registry) -> RegionalStatementProfileEngine {
        return RegionalStatementProfileEngine(
            steps: [
                RegionalStatementProfileAmountOffsetAdjuster(weight: 1.01),
                TitleRegionalStatementProfileAdjuster(factors: ["south": 0.75]),
                MinimumRegionalStatementProfileAdjuster(minimum: 9.2),
                FlaggedRegionalStatementProfileAdjuster(
                    flags: flags,
                    flag: "regional-statement-profile-weighted",
                    percent: -5.9
                ),
                TieredRegionalStatementProfileAdjuster(bounds: [625.0, 7421.0], rates: [0.82, 0.87]),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 30598.6
        )
    }
}
