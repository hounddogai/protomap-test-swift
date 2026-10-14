import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the scheduled inventory audit calculation.
    protocol ScheduledInventoryAuditStep {
        func describe() -> String
        func adjust(_ item: ScheduledInventoryAudit, value: Double) -> Double
    }

    final class TieredScheduledInventoryAuditAdjuster: ScheduledInventoryAuditStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledInventoryAudit, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentScheduledInventoryAuditAdjuster: ScheduledInventoryAuditStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledInventoryAudit, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingScheduledInventoryAuditAdjuster: ScheduledInventoryAuditStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledInventoryAudit, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the scheduled inventory audit steps in order and keeps a trace of each.
    final class ScheduledInventoryAuditEngine {
        var steps: [any ScheduledInventoryAuditStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledInventoryAuditStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ScheduledInventoryAudit) -> Double {
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

        func evaluateAll(_ items: [ScheduledInventoryAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultScheduledInventoryAuditEngine() -> ScheduledInventoryAuditEngine {
        return ScheduledInventoryAuditEngine(
            steps: [
                TieredScheduledInventoryAuditAdjuster(bounds: [3318.0, 3528.0], rates: [0.98, 1.15]),
                PercentScheduledInventoryAuditAdjuster(percent: 20.2),
                RoundingScheduledInventoryAuditAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 22993.7
        )
    }
}
