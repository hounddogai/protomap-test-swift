import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the census batch calculation.
    protocol CensusBatchAdjuster {
        func describe() -> String
        func adjust(_ item: CensusBatch, value: Double) -> Double
    }

    final class PercentCensusBatchAdjuster: CensusBatchAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CensusBatch, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredCensusBatchAdjuster: CensusBatchAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CensusBatch, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class SourceCensusBatchAdjuster: CensusBatchAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: CensusBatch, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingCensusBatchAdjuster: CensusBatchAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CensusBatch, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedCensusBatchAdjuster: CensusBatchAdjuster {
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

        func adjust(_ item: CensusBatch, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapCensusBatchAdjuster: CensusBatchAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CensusBatch, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the census batch steps in order and keeps a trace of each.
    final class CensusBatchEngine {
        var steps: [any CensusBatchAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CensusBatchAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CensusBatch) -> Double {
            var current = item.netLoad()
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

        func evaluateAll(_ items: [CensusBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCensusBatchEngine(_ flags: Kit.Flags.Registry) -> CensusBatchEngine {
        return CensusBatchEngine(
            steps: [
                PercentCensusBatchAdjuster(percent: 2.3),
                TieredCensusBatchAdjuster(bounds: [6610.0, 8028.0], rates: [1.0, 0.81]),
                SourceCensusBatchAdjuster(factors: ["east": 1.28, "west": 0.71]),
                RoundingCensusBatchAdjuster(step: 1.0),
                FlaggedCensusBatchAdjuster(flags: flags, flag: "census-batch-fallback", percent: 7.0),
                CapCensusBatchAdjuster(cap: 22306.0),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 71312.8
        )
    }
}
