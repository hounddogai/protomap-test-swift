import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the legacy slot record calculation.
    protocol LegacySlotRecordStep {
        func describe() -> String
        func adjust(_ item: LegacySlotRecord, value: Double) -> Double
    }

    final class TitleLegacySlotRecordAdjuster: LegacySlotRecordStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: LegacySlotRecord, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredLegacySlotRecordAdjuster: LegacySlotRecordStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacySlotRecord, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedLegacySlotRecordAdjuster: LegacySlotRecordStep {
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

        func adjust(_ item: LegacySlotRecord, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingLegacySlotRecordAdjuster: LegacySlotRecordStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacySlotRecord, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentLegacySlotRecordAdjuster: LegacySlotRecordStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LegacySlotRecord, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapLegacySlotRecordAdjuster: LegacySlotRecordStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacySlotRecord, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the legacy slot record steps in order and keeps a trace of each.
    final class LegacySlotRecordEngine {
        var steps: [any LegacySlotRecordStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacySlotRecordStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LegacySlotRecord) -> Double {
            var current = item.projectedValue()
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

        func evaluateAll(_ items: [LegacySlotRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLegacySlotRecordEngine(_ flags: Kit.Flags.Registry) -> LegacySlotRecordEngine {
        return LegacySlotRecordEngine(
            steps: [
                TitleLegacySlotRecordAdjuster(factors: ["south": 1.36, "north": 1.4, "west": 1.31]),
                TieredLegacySlotRecordAdjuster(bounds: [3563.0, 6001.0, 8988.0], rates: [1.06, 0.84, 1.02]),
                FlaggedLegacySlotRecordAdjuster(flags: flags, flag: "legacy-slot-record-adaptive", percent: -8.5),
                RoundingLegacySlotRecordAdjuster(step: 5.0),
                PercentLegacySlotRecordAdjuster(percent: 3.1),
                CapLegacySlotRecordAdjuster(cap: 23575.0),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 59061.2
        )
    }
}
