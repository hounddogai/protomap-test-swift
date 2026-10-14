import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the regional worklist record calculation.
    protocol RegionalWorklistRecordStep {
        func describe() -> String
        func adjust(_ item: RegionalWorklistRecord, value: Double) -> Double
    }

    final class TieredRegionalWorklistRecordAdjuster: RegionalWorklistRecordStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalWorklistRecord, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedRegionalWorklistRecordAdjuster: RegionalWorklistRecordStep {
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

        func adjust(_ item: RegionalWorklistRecord, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CategoryRegionalWorklistRecordAdjuster: RegionalWorklistRecordStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: RegionalWorklistRecord, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingRegionalWorklistRecordAdjuster: RegionalWorklistRecordStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalWorklistRecord, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the regional worklist record steps in order and keeps a trace of each.
    final class RegionalWorklistRecordEngine {
        var steps: [any RegionalWorklistRecordStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalWorklistRecordStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RegionalWorklistRecord) -> Double {
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

        func evaluateAll(_ items: [RegionalWorklistRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRegionalWorklistRecordEngine(_ flags: Kit.Flags.Registry) -> RegionalWorklistRecordEngine {
        return RegionalWorklistRecordEngine(
            steps: [
                TieredRegionalWorklistRecordAdjuster(
                    bounds: [6662.0, 9435.0, 9537.0, 9584.0],
                    rates: [1.0, 1.09, 1.19, 1.18]
                ),
                FlaggedRegionalWorklistRecordAdjuster(
                    flags: flags,
                    flag: "regional-worklist-record-primary",
                    percent: -6.7
                ),
                CategoryRegionalWorklistRecordAdjuster(factors: ["north": 0.76]),
                RoundingRegionalWorklistRecordAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 67969.0
        )
    }
}
