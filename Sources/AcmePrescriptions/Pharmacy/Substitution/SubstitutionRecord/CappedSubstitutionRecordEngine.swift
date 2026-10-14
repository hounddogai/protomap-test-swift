import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the capped substitution record calculation.
    protocol CappedSubstitutionRecordFactor {
        func describe() -> String
        func adjust(_ item: CappedSubstitutionRecord, value: Double) -> Double
    }

    final class CapCappedSubstitutionRecordAdjuster: CappedSubstitutionRecordFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedSubstitutionRecord, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LabelCappedSubstitutionRecordAdjuster: CappedSubstitutionRecordFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: CappedSubstitutionRecord, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredCappedSubstitutionRecordAdjuster: CappedSubstitutionRecordFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedSubstitutionRecord, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedCappedSubstitutionRecordAdjuster: CappedSubstitutionRecordFactor {
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

        func adjust(_ item: CappedSubstitutionRecord, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the capped substitution record steps in order and keeps a trace of each.
    final class CappedSubstitutionRecordEngine {
        var steps: [any CappedSubstitutionRecordFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedSubstitutionRecordFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CappedSubstitutionRecord) -> Double {
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

        func evaluateAll(_ items: [CappedSubstitutionRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCappedSubstitutionRecordEngine(_ flags: Kit.Flags.Registry) -> CappedSubstitutionRecordEngine {
        return CappedSubstitutionRecordEngine(
            steps: [
                CapCappedSubstitutionRecordAdjuster(cap: 41040.0),
                LabelCappedSubstitutionRecordAdjuster(factors: ["central": 1.23, "west": 0.98]),
                TieredCappedSubstitutionRecordAdjuster(bounds: [4991.0, 6959.0, 7613.0], rates: [1.05, 0.81, 0.93]),
                FlaggedCappedSubstitutionRecordAdjuster(
                    flags: flags,
                    flag: "capped-substitution-record-capped",
                    percent: -5.7
                ),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 79809.2
        )
    }
}
