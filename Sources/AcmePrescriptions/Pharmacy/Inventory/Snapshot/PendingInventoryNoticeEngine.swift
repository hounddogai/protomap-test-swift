import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the pending inventory notice calculation.
    protocol PendingInventoryNoticeAdjuster {
        func describe() -> String
        func adjust(_ item: PendingInventoryNotice, value: Double) -> Double
    }

    final class MinimumPendingInventoryNoticeAdjuster: PendingInventoryNoticeAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingInventoryNotice, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredPendingInventoryNoticeAdjuster: PendingInventoryNoticeAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PendingInventoryNotice, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PendingInventoryNoticeVisitMinutesOffsetAdjuster: PendingInventoryNoticeAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus visit minutes times \(weight)"
        }

        func adjust(_ item: PendingInventoryNotice, value: Double) -> Double {
            return value + Double(item.visitMinutes) * weight
        }
    }

    /// Runs the pending inventory notice steps in order and keeps a trace of each.
    final class PendingInventoryNoticeEngine {
        var steps: [any PendingInventoryNoticeAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingInventoryNoticeAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PendingInventoryNotice) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingInventoryNoticeAdjuster = steps[index]
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

        func evaluateAll(_ items: [PendingInventoryNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPendingInventoryNoticeEngine() -> PendingInventoryNoticeEngine {
        return PendingInventoryNoticeEngine(
            steps: [
                MinimumPendingInventoryNoticeAdjuster(minimum: 15.3),
                TieredPendingInventoryNoticeAdjuster(
                    bounds: [4170.0, 5156.0, 7083.0, 8453.0],
                    rates: [1.07, 0.85, 1.02, 0.93]
                ),
                PendingInventoryNoticeVisitMinutesOffsetAdjuster(weight: 0.24),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 57710.3
        )
    }
}
