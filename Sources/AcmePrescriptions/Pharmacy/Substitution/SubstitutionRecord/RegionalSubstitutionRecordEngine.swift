import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the regional substitution record calculation.
    protocol RegionalSubstitutionRecordFactor {
        func describe() -> String
        func adjust(_ item: RegionalSubstitutionRecord, value: Double) -> Double
    }

    final class MinimumRegionalSubstitutionRecordAdjuster: RegionalSubstitutionRecordFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalSubstitutionRecord, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedRegionalSubstitutionRecordAdjuster: RegionalSubstitutionRecordFactor {
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

        func adjust(_ item: RegionalSubstitutionRecord, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RegionalSubstitutionRecordRefillsOffsetAdjuster: RegionalSubstitutionRecordFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus refills times \(weight)"
        }

        func adjust(_ item: RegionalSubstitutionRecord, value: Double) -> Double {
            return value + Double(item.refills) * weight
        }
    }

    final class TitleRegionalSubstitutionRecordAdjuster: RegionalSubstitutionRecordFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: RegionalSubstitutionRecord, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentRegionalSubstitutionRecordAdjuster: RegionalSubstitutionRecordFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalSubstitutionRecord, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the regional substitution record steps in order and keeps a trace of each.
    final class RegionalSubstitutionRecordEngine {
        var steps: [any RegionalSubstitutionRecordFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalSubstitutionRecordFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RegionalSubstitutionRecord) -> Double {
            var current = item.projectedExposure()
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

        func evaluateAll(_ items: [RegionalSubstitutionRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRegionalSubstitutionRecordEngine(_ flags: Kit.Flags.Registry) -> RegionalSubstitutionRecordEngine {
        return RegionalSubstitutionRecordEngine(
            steps: [
                MinimumRegionalSubstitutionRecordAdjuster(minimum: 31.9),
                FlaggedRegionalSubstitutionRecordAdjuster(
                    flags: flags,
                    flag: "regional-substitution-record-global",
                    percent: 1.9
                ),
                RegionalSubstitutionRecordRefillsOffsetAdjuster(weight: 1.75),
                TitleRegionalSubstitutionRecordAdjuster(factors: ["online": 1.32, "west": 1.07]),
                PercentRegionalSubstitutionRecordAdjuster(percent: 21.7),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 69071.8
        )
    }
}
