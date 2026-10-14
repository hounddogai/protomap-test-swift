import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the dispense threshold calculation.
    protocol DispenseThresholdFactor {
        func describe() -> String
        func adjust(_ item: DispenseThreshold, value: Double) -> Double
    }

    final class TieredDispenseThresholdAdjuster: DispenseThresholdFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DispenseThreshold, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedDispenseThresholdAdjuster: DispenseThresholdFactor {
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

        func adjust(_ item: DispenseThreshold, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingDispenseThresholdAdjuster: DispenseThresholdFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DispenseThreshold, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapDispenseThresholdAdjuster: DispenseThresholdFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DispenseThreshold, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the dispense threshold steps in order and keeps a trace of each.
    final class DispenseThresholdEngine {
        var steps: [any DispenseThresholdFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DispenseThresholdFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DispenseThreshold) -> Double {
            var current = item.netExposure()
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

        func evaluateAll(_ items: [DispenseThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDispenseThresholdEngine(_ flags: Kit.Flags.Registry) -> DispenseThresholdEngine {
        return DispenseThresholdEngine(
            steps: [
                TieredDispenseThresholdAdjuster(bounds: [1963.0, 5389.0], rates: [1.18, 1.01]),
                FlaggedDispenseThresholdAdjuster(flags: flags, flag: "dispense-threshold-rolling", percent: 0.6),
                RoundingDispenseThresholdAdjuster(step: 5.0),
                CapDispenseThresholdAdjuster(cap: 3345.0),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 48379.4
        )
    }
}
