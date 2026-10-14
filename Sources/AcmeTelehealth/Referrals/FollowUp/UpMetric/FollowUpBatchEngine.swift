import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the follow up batch calculation.
    protocol FollowUpBatchAdjuster {
        func describe() -> String
        func adjust(_ item: FollowUpBatch, value: Double) -> Double
    }

    final class MinimumFollowUpBatchAdjuster: FollowUpBatchAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FollowUpBatch, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapFollowUpBatchAdjuster: FollowUpBatchAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FollowUpBatch, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedFollowUpBatchAdjuster: FollowUpBatchAdjuster {
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

        func adjust(_ item: FollowUpBatch, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameFollowUpBatchAdjuster: FollowUpBatchAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: FollowUpBatch, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the follow up batch steps in order and keeps a trace of each.
    final class FollowUpBatchEngine {
        var steps: [any FollowUpBatchAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FollowUpBatchAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FollowUpBatch) -> Double {
            var current = item.projectedVolume()
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

        func evaluateAll(_ items: [FollowUpBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFollowUpBatchEngine(_ flags: Kit.Flags.Registry) -> FollowUpBatchEngine {
        return FollowUpBatchEngine(
            steps: [
                MinimumFollowUpBatchAdjuster(minimum: 17.1),
                CapFollowUpBatchAdjuster(cap: 7188.0),
                FlaggedFollowUpBatchAdjuster(flags: flags, flag: "follow-up-batch-regional", percent: 4.0),
                NameFollowUpBatchAdjuster(factors: ["central": 1.14]),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 65267.3
        )
    }
}
