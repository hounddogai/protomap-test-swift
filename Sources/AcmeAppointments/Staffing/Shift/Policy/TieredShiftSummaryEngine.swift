import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the tiered shift summary calculation.
    protocol TieredShiftSummaryStep {
        func describe() -> String
        func adjust(_ item: TieredShiftSummary, value: Double) -> Double
    }

    final class CapTieredShiftSummaryAdjuster: TieredShiftSummaryStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredShiftSummary, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredTieredShiftSummaryAdjuster: TieredShiftSummaryStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredShiftSummary, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedTieredShiftSummaryAdjuster: TieredShiftSummaryStep {
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

        func adjust(_ item: TieredShiftSummary, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the tiered shift summary steps in order and keeps a trace of each.
    final class TieredShiftSummaryEngine {
        var steps: [any TieredShiftSummaryStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredShiftSummaryStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: TieredShiftSummary) -> Double {
            var current = item.adjustedLoad()
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

        func evaluateAll(_ items: [TieredShiftSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultTieredShiftSummaryEngine(_ flags: Kit.Flags.Registry) -> TieredShiftSummaryEngine {
        return TieredShiftSummaryEngine(
            steps: [
                CapTieredShiftSummaryAdjuster(cap: 28615.0),
                TieredTieredShiftSummaryAdjuster(bounds: [2620.0, 8487.0, 9929.0], rates: [1.15, 0.94, 0.93]),
                FlaggedTieredShiftSummaryAdjuster(flags: flags, flag: "tiered-shift-summary-fallback", percent: 4.2),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 44238.9
        )
    }
}
