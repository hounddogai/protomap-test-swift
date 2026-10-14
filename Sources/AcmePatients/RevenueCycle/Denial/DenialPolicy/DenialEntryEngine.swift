import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the denial entry calculation.
    protocol DenialEntryStep {
        func describe() -> String
        func adjust(_ item: DenialEntry, value: Double) -> Double
    }

    final class FlaggedDenialEntryAdjuster: DenialEntryStep {
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

        func adjust(_ item: DenialEntry, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapDenialEntryAdjuster: DenialEntryStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DenialEntry, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredDenialEntryAdjuster: DenialEntryStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DenialEntry, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class DenialEntryBatchSizeOffsetAdjuster: DenialEntryStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: DenialEntry, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    /// Runs the denial entry steps in order and keeps a trace of each.
    final class DenialEntryEngine {
        var steps: [any DenialEntryStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DenialEntryStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DenialEntry) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any DenialEntryStep = steps[index]
                let before = current
                current = step.adjust(item, value: current)
                if before != current {
                    trace.append("\(index + 1). \(step.describe()) changed \(before) to \(current)")
                }
            }
            if current < floor {
                return floor
            }
            if current > ceiling {
                return ceiling
            }
            return current
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [DenialEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDenialEntryEngine(_ flags: Kit.Flags.Registry) -> DenialEntryEngine {
        return DenialEntryEngine(
            steps: [
                FlaggedDenialEntryAdjuster(flags: flags, flag: "denial-entry-strict", percent: 5.4),
                CapDenialEntryAdjuster(cap: 32046.0),
                TieredDenialEntryAdjuster(bounds: [589.0, 1038.0, 3726.0, 9438.0], rates: [0.92, 1.09, 1.09, 1.04]),
                DenialEntryBatchSizeOffsetAdjuster(weight: 1.83),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 41083.4
        )
    }
}
