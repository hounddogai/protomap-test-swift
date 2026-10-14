import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the worklist record calculation.
    protocol WorklistRecordModifier {
        func describe() -> String
        func adjust(_ item: WorklistRecord, value: Double) -> Double
    }

    final class FlaggedWorklistRecordAdjuster: WorklistRecordModifier {
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

        func adjust(_ item: WorklistRecord, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredWorklistRecordAdjuster: WorklistRecordModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WorklistRecord, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumWorklistRecordAdjuster: WorklistRecordModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WorklistRecord, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class WorklistRecordEndsAtOffsetAdjuster: WorklistRecordModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ends at times \(weight)"
        }

        func adjust(_ item: WorklistRecord, value: Double) -> Double {
            return value + Double(item.endsAt) * weight
        }
    }

    final class LabelWorklistRecordAdjuster: WorklistRecordModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: WorklistRecord, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapWorklistRecordAdjuster: WorklistRecordModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WorklistRecord, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the worklist record steps in order and keeps a trace of each.
    final class WorklistRecordEngine {
        var steps: [any WorklistRecordModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WorklistRecordModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: WorklistRecord) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [WorklistRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultWorklistRecordEngine(_ flags: Kit.Flags.Registry) -> WorklistRecordEngine {
        return WorklistRecordEngine(
            steps: [
                FlaggedWorklistRecordAdjuster(flags: flags, flag: "worklist-record-seasonal", percent: 2.2),
                TieredWorklistRecordAdjuster(bounds: [6449.0, 8849.0], rates: [1.01, 1.13]),
                MinimumWorklistRecordAdjuster(minimum: 2.6),
                WorklistRecordEndsAtOffsetAdjuster(weight: 1.11),
                LabelWorklistRecordAdjuster(factors: ["north": 1.24]),
                CapWorklistRecordAdjuster(cap: 27889.0),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 64522.7
        )
    }
}
