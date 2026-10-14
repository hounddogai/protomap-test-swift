import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the batched dispense profile calculation.
    protocol BatchedDispenseProfileFactor {
        func describe() -> String
        func adjust(_ item: BatchedDispenseProfile, value: Double) -> Double
    }

    final class BatchedDispenseProfileDurationMinutesOffsetAdjuster: BatchedDispenseProfileFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus duration minutes times \(weight)"
        }

        func adjust(_ item: BatchedDispenseProfile, value: Double) -> Double {
            return value + Double(item.durationMinutes) * weight
        }
    }

    final class MinimumBatchedDispenseProfileAdjuster: BatchedDispenseProfileFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedDispenseProfile, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredBatchedDispenseProfileAdjuster: BatchedDispenseProfileFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedDispenseProfile, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapBatchedDispenseProfileAdjuster: BatchedDispenseProfileFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedDispenseProfile, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentBatchedDispenseProfileAdjuster: BatchedDispenseProfileFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedDispenseProfile, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedBatchedDispenseProfileAdjuster: BatchedDispenseProfileFactor {
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

        func adjust(_ item: BatchedDispenseProfile, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the batched dispense profile steps in order and keeps a trace of each.
    final class BatchedDispenseProfileEngine {
        var steps: [any BatchedDispenseProfileFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedDispenseProfileFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: BatchedDispenseProfile) -> Double {
            var current = item.netTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedDispenseProfileFactor = steps[index]
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

        func evaluateAll(_ items: [BatchedDispenseProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultBatchedDispenseProfileEngine(_ flags: Kit.Flags.Registry) -> BatchedDispenseProfileEngine {
        return BatchedDispenseProfileEngine(
            steps: [
                BatchedDispenseProfileDurationMinutesOffsetAdjuster(weight: 1.7),
                MinimumBatchedDispenseProfileAdjuster(minimum: 31.5),
                TieredBatchedDispenseProfileAdjuster(bounds: [5015.0, 9407.0], rates: [0.95, 1.06]),
                CapBatchedDispenseProfileAdjuster(cap: 3549.0),
                PercentBatchedDispenseProfileAdjuster(percent: 22.8),
                FlaggedBatchedDispenseProfileAdjuster(
                    flags: flags,
                    flag: "batched-dispense-profile-seasonal",
                    percent: -6.6
                ),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 41435.7
        )
    }
}
