import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the regional care protocol estimate calculation.
    protocol RegionalCareProtocolEstimateStep {
        func describe() -> String
        func adjust(_ item: RegionalCareProtocolEstimate, value: Double) -> Double
    }

    final class UnitRegionalCareProtocolEstimateAdjuster: RegionalCareProtocolEstimateStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: RegionalCareProtocolEstimate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredRegionalCareProtocolEstimateAdjuster: RegionalCareProtocolEstimateStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalCareProtocolEstimate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapRegionalCareProtocolEstimateAdjuster: RegionalCareProtocolEstimateStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalCareProtocolEstimate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentRegionalCareProtocolEstimateAdjuster: RegionalCareProtocolEstimateStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalCareProtocolEstimate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingRegionalCareProtocolEstimateAdjuster: RegionalCareProtocolEstimateStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalCareProtocolEstimate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedRegionalCareProtocolEstimateAdjuster: RegionalCareProtocolEstimateStep {
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

        func adjust(_ item: RegionalCareProtocolEstimate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the regional care protocol estimate steps in order and keeps a trace of each.
    final class RegionalCareProtocolEstimateEngine {
        var steps: [any RegionalCareProtocolEstimateStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalCareProtocolEstimateStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RegionalCareProtocolEstimate) -> Double {
            var current = item.netTotal()
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

        func evaluateAll(_ items: [RegionalCareProtocolEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRegionalCareProtocolEstimateEngine(_ flags: Kit.Flags.Registry) -> RegionalCareProtocolEstimateEngine {
        return RegionalCareProtocolEstimateEngine(
            steps: [
                UnitRegionalCareProtocolEstimateAdjuster(factors: ["west": 1.36, "north": 0.93]),
                TieredRegionalCareProtocolEstimateAdjuster(bounds: [880.0, 8006.0], rates: [0.91, 0.91]),
                CapRegionalCareProtocolEstimateAdjuster(cap: 36835.0),
                PercentRegionalCareProtocolEstimateAdjuster(percent: -2.3),
                RoundingRegionalCareProtocolEstimateAdjuster(step: 0.1),
                FlaggedRegionalCareProtocolEstimateAdjuster(
                    flags: flags,
                    flag: "regional-care-protocol-estimate-fallback",
                    percent: 8.7
                ),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 52759.5
        )
    }
}
