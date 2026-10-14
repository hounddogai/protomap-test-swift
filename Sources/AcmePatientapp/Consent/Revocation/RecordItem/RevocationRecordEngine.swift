import AcmePlatform
import Foundation

extension Consent {
    /// One step of the revocation record calculation.
    protocol RevocationRecordFactor {
        func describe() -> String
        func adjust(_ item: RevocationRecord, value: Double) -> Double
    }

    final class RoundingRevocationRecordAdjuster: RevocationRecordFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RevocationRecord, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedRevocationRecordAdjuster: RevocationRecordFactor {
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

        func adjust(_ item: RevocationRecord, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelRevocationRecordAdjuster: RevocationRecordFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: RevocationRecord, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RevocationRecordWindowDaysOffsetAdjuster: RevocationRecordFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: RevocationRecord, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    final class MinimumRevocationRecordAdjuster: RevocationRecordFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RevocationRecord, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredRevocationRecordAdjuster: RevocationRecordFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RevocationRecord, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the revocation record steps in order and keeps a trace of each.
    final class RevocationRecordEngine {
        var steps: [any RevocationRecordFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RevocationRecordFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RevocationRecord) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RevocationRecordFactor = steps[index]
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

        func evaluateAll(_ items: [RevocationRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRevocationRecordEngine(_ flags: Kit.Flags.Registry) -> RevocationRecordEngine {
        return RevocationRecordEngine(
            steps: [
                RoundingRevocationRecordAdjuster(step: 0.5),
                FlaggedRevocationRecordAdjuster(flags: flags, flag: "revocation-record-fallback", percent: 2.5),
                LabelRevocationRecordAdjuster(factors: ["north": 1.16]),
                RevocationRecordWindowDaysOffsetAdjuster(weight: 0.13),
                MinimumRevocationRecordAdjuster(minimum: 30.0),
                TieredRevocationRecordAdjuster(
                    bounds: [1104.0, 1473.0, 8025.0, 9230.0],
                    rates: [1.03, 1.04, 1.08, 1.0]
                ),
            ],
            trace: [],
            floor: 0.0,
            ceiling: 30945.9
        )
    }
}
