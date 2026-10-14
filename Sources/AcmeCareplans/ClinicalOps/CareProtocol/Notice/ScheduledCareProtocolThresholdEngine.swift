import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the scheduled care protocol threshold calculation.
    protocol ScheduledCareProtocolThresholdFactor {
        func describe() -> String
        func adjust(_ item: ScheduledCareProtocolThreshold, value: Double) -> Double
    }

    final class FlaggedScheduledCareProtocolThresholdAdjuster: ScheduledCareProtocolThresholdFactor {
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

        func adjust(_ item: ScheduledCareProtocolThreshold, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapScheduledCareProtocolThresholdAdjuster: ScheduledCareProtocolThresholdFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledCareProtocolThreshold, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredScheduledCareProtocolThresholdAdjuster: ScheduledCareProtocolThresholdFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledCareProtocolThreshold, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingScheduledCareProtocolThresholdAdjuster: ScheduledCareProtocolThresholdFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledCareProtocolThreshold, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the scheduled care protocol threshold steps in order and keeps a trace of each.
    final class ScheduledCareProtocolThresholdEngine {
        var steps: [any ScheduledCareProtocolThresholdFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledCareProtocolThresholdFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ScheduledCareProtocolThreshold) -> Double {
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

        func evaluateAll(_ items: [ScheduledCareProtocolThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultScheduledCareProtocolThresholdEngine(_ flags: Kit.Flags.Registry) -> ScheduledCareProtocolThresholdEngine {
        return ScheduledCareProtocolThresholdEngine(
            steps: [
                FlaggedScheduledCareProtocolThresholdAdjuster(
                    flags: flags,
                    flag: "scheduled-care-protocol-threshold-legacy",
                    percent: -3.7
                ),
                CapScheduledCareProtocolThresholdAdjuster(cap: 22208.0),
                TieredScheduledCareProtocolThresholdAdjuster(
                    bounds: [554.0, 1945.0, 4935.0, 9598.0],
                    rates: [1.16, 0.84, 1.16, 1.15]
                ),
                RoundingScheduledCareProtocolThresholdAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 15525.5
        )
    }
}
