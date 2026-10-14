import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the strict slot record calculation.
    protocol StrictSlotRecordModifier {
        func describe() -> String
        func adjust(_ item: StrictSlotRecord, value: Double) -> Double
    }

    final class MinimumStrictSlotRecordAdjuster: StrictSlotRecordModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictSlotRecord, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapStrictSlotRecordAdjuster: StrictSlotRecordModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StrictSlotRecord, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class StrictSlotRecordRevisionOffsetAdjuster: StrictSlotRecordModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus revision times \(weight)"
        }

        func adjust(_ item: StrictSlotRecord, value: Double) -> Double {
            return value + Double(item.revision) * weight
        }
    }

    final class LabelStrictSlotRecordAdjuster: StrictSlotRecordModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: StrictSlotRecord, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedStrictSlotRecordAdjuster: StrictSlotRecordModifier {
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

        func adjust(_ item: StrictSlotRecord, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredStrictSlotRecordAdjuster: StrictSlotRecordModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictSlotRecord, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the strict slot record steps in order and keeps a trace of each.
    final class StrictSlotRecordEngine {
        var steps: [any StrictSlotRecordModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictSlotRecordModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: StrictSlotRecord) -> Double {
            var current = item.netValue()
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

        func evaluateAll(_ items: [StrictSlotRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultStrictSlotRecordEngine(_ flags: Kit.Flags.Registry) -> StrictSlotRecordEngine {
        return StrictSlotRecordEngine(
            steps: [
                MinimumStrictSlotRecordAdjuster(minimum: 1.1),
                CapStrictSlotRecordAdjuster(cap: 23543.0),
                StrictSlotRecordRevisionOffsetAdjuster(weight: 0.96),
                LabelStrictSlotRecordAdjuster(factors: ["west": 1.4, "online": 0.99, "east": 0.76]),
                FlaggedStrictSlotRecordAdjuster(flags: flags, flag: "strict-slot-record-default", percent: -3.0),
                TieredStrictSlotRecordAdjuster(bounds: [1497.0, 6508.0], rates: [0.87, 1.17]),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 89114.9
        )
    }
}
