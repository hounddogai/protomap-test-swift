import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the default priority audit calculation.
    protocol DefaultPriorityAuditAdjuster {
        func describe() -> String
        func adjust(_ item: DefaultPriorityAudit, value: Double) -> Double
    }

    final class TieredDefaultPriorityAuditAdjuster: DefaultPriorityAuditAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultPriorityAudit, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class SourceDefaultPriorityAuditAdjuster: DefaultPriorityAuditAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: DefaultPriorityAudit, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentDefaultPriorityAuditAdjuster: DefaultPriorityAuditAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultPriorityAudit, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the default priority audit steps in order and keeps a trace of each.
    final class DefaultPriorityAuditEngine {
        var steps: [any DefaultPriorityAuditAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultPriorityAuditAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DefaultPriorityAudit) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultPriorityAuditAdjuster = steps[index]
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

        func evaluateAll(_ items: [DefaultPriorityAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDefaultPriorityAuditEngine() -> DefaultPriorityAuditEngine {
        return DefaultPriorityAuditEngine(
            steps: [
                TieredDefaultPriorityAuditAdjuster(bounds: [273.0, 5765.0], rates: [1.2, 0.87]),
                SourceDefaultPriorityAuditAdjuster(factors: ["west": 0.93, "east": 1.23]),
                PercentDefaultPriorityAuditAdjuster(percent: 16.5),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 98406.9
        )
    }
}
