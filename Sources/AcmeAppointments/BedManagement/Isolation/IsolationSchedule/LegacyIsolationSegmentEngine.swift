import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the legacy isolation segment calculation.
    protocol LegacyIsolationSegmentFactor {
        func describe() -> String
        func adjust(_ item: LegacyIsolationSegment, value: Double) -> Double
    }

    final class FlaggedLegacyIsolationSegmentAdjuster: LegacyIsolationSegmentFactor {
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

        func adjust(_ item: LegacyIsolationSegment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SourceLegacyIsolationSegmentAdjuster: LegacyIsolationSegmentFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: LegacyIsolationSegment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredLegacyIsolationSegmentAdjuster: LegacyIsolationSegmentFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyIsolationSegment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the legacy isolation segment steps in order and keeps a trace of each.
    final class LegacyIsolationSegmentEngine {
        var steps: [any LegacyIsolationSegmentFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyIsolationSegmentFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LegacyIsolationSegment) -> Double {
            var current = item.effectiveVolume()
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

        func evaluateAll(_ items: [LegacyIsolationSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLegacyIsolationSegmentEngine(_ flags: Kit.Flags.Registry) -> LegacyIsolationSegmentEngine {
        return LegacyIsolationSegmentEngine(
            steps: [
                FlaggedLegacyIsolationSegmentAdjuster(
                    flags: flags,
                    flag: "legacy-isolation-segment-manual",
                    percent: 9.5
                ),
                SourceLegacyIsolationSegmentAdjuster(factors: ["central": 1.09, "retail": 0.79]),
                TieredLegacyIsolationSegmentAdjuster(bounds: [4363.0, 5663.0, 8972.0], rates: [1.05, 1.06, 1.19]),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 41076.3
        )
    }
}
