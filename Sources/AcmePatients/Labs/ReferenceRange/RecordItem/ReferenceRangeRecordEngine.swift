import AcmePlatform
import Foundation

extension Labs {
    /// One step of the reference range record calculation.
    protocol ReferenceRangeRecordStep {
        func describe() -> String
        func adjust(_ item: ReferenceRangeRecord, value: Double) -> Double
    }

    final class TieredReferenceRangeRecordAdjuster: ReferenceRangeRecordStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ReferenceRangeRecord, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedReferenceRangeRecordAdjuster: ReferenceRangeRecordStep {
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

        func adjust(_ item: ReferenceRangeRecord, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumReferenceRangeRecordAdjuster: ReferenceRangeRecordStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ReferenceRangeRecord, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentReferenceRangeRecordAdjuster: ReferenceRangeRecordStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ReferenceRangeRecord, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameReferenceRangeRecordAdjuster: ReferenceRangeRecordStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: ReferenceRangeRecord, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapReferenceRangeRecordAdjuster: ReferenceRangeRecordStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ReferenceRangeRecord, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the reference range record steps in order and keeps a trace of each.
    final class ReferenceRangeRecordEngine {
        var steps: [any ReferenceRangeRecordStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReferenceRangeRecordStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ReferenceRangeRecord) -> Double {
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

        func evaluateAll(_ items: [ReferenceRangeRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultReferenceRangeRecordEngine(_ flags: Kit.Flags.Registry) -> ReferenceRangeRecordEngine {
        return ReferenceRangeRecordEngine(
            steps: [
                TieredReferenceRangeRecordAdjuster(
                    bounds: [363.0, 368.0, 4883.0, 5559.0],
                    rates: [0.96, 0.85, 0.86, 1.13]
                ),
                FlaggedReferenceRangeRecordAdjuster(
                    flags: flags,
                    flag: "reference-range-record-rolling",
                    percent: 7.5
                ),
                MinimumReferenceRangeRecordAdjuster(minimum: 23.2),
                PercentReferenceRangeRecordAdjuster(percent: -7.0),
                NameReferenceRangeRecordAdjuster(factors: ["south": 1.03]),
                CapReferenceRangeRecordAdjuster(cap: 4750.0),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 35039.9
        )
    }
}
