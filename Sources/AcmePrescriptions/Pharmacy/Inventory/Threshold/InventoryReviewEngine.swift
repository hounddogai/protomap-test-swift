import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the inventory review calculation.
    protocol InventoryReviewAdjuster {
        func describe() -> String
        func adjust(_ item: InventoryReview, value: Double) -> Double
    }

    final class FlaggedInventoryReviewAdjuster: InventoryReviewAdjuster {
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

        func adjust(_ item: InventoryReview, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ChannelInventoryReviewAdjuster: InventoryReviewAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: InventoryReview, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class InventoryReviewAttemptsOffsetAdjuster: InventoryReviewAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: InventoryReview, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    /// Runs the inventory review steps in order and keeps a trace of each.
    final class InventoryReviewEngine {
        var steps: [any InventoryReviewAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InventoryReviewAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: InventoryReview) -> Double {
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

        func evaluateAll(_ items: [InventoryReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultInventoryReviewEngine(_ flags: Kit.Flags.Registry) -> InventoryReviewEngine {
        return InventoryReviewEngine(
            steps: [
                FlaggedInventoryReviewAdjuster(flags: flags, flag: "inventory-review-pending", percent: -5.5),
                ChannelInventoryReviewAdjuster(factors: ["central": 0.84]),
                InventoryReviewAttemptsOffsetAdjuster(weight: 0.1),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 91940.3
        )
    }
}
