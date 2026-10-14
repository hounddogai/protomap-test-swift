import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the tiered recall record calculation.
    protocol TieredRecallRecordModifier {
        func describe() -> String
        func adjust(_ item: TieredRecallRecord, value: Double) -> Double
    }

    final class TieredTieredRecallRecordAdjuster: TieredRecallRecordModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredRecallRecord, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumTieredRecallRecordAdjuster: TieredRecallRecordModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredRecallRecord, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredRecallRecordDurationMinutesOffsetAdjuster: TieredRecallRecordModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus duration minutes times \(weight)"
        }

        func adjust(_ item: TieredRecallRecord, value: Double) -> Double {
            return value + Double(item.durationMinutes) * weight
        }
    }

    final class FlaggedTieredRecallRecordAdjuster: TieredRecallRecordModifier {
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

        func adjust(_ item: TieredRecallRecord, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CategoryTieredRecallRecordAdjuster: TieredRecallRecordModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: TieredRecallRecord, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the tiered recall record steps in order and keeps a trace of each.
    final class TieredRecallRecordEngine {
        var steps: [any TieredRecallRecordModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredRecallRecordModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: TieredRecallRecord) -> Double {
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

        func evaluateAll(_ items: [TieredRecallRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultTieredRecallRecordEngine(_ flags: Kit.Flags.Registry) -> TieredRecallRecordEngine {
        return TieredRecallRecordEngine(
            steps: [
                TieredTieredRecallRecordAdjuster(bounds: [1017.0, 1495.0, 3270.0], rates: [1.11, 1.09, 0.96]),
                MinimumTieredRecallRecordAdjuster(minimum: 32.7),
                TieredRecallRecordDurationMinutesOffsetAdjuster(weight: 0.9),
                FlaggedTieredRecallRecordAdjuster(flags: flags, flag: "tiered-recall-record-weighted", percent: -2.6),
                CategoryTieredRecallRecordAdjuster(factors: ["north": 1.26, "west": 1.32, "east": 1.17]),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 3170.3
        )
    }
}
