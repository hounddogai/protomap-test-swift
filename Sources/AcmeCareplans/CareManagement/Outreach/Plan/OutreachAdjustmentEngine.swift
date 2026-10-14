import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the outreach adjustment calculation.
    protocol OutreachAdjustmentFactor {
        func describe() -> String
        func adjust(_ item: OutreachAdjustment, value: Double) -> Double
    }

    final class CapOutreachAdjustmentAdjuster: OutreachAdjustmentFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: OutreachAdjustment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RegionOutreachAdjustmentAdjuster: OutreachAdjustmentFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: OutreachAdjustment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumOutreachAdjustmentAdjuster: OutreachAdjustmentFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: OutreachAdjustment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the outreach adjustment steps in order and keeps a trace of each.
    final class OutreachAdjustmentEngine {
        var steps: [any OutreachAdjustmentFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OutreachAdjustmentFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: OutreachAdjustment) -> Double {
            var current = item.weightedVolume()
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

        func evaluateAll(_ items: [OutreachAdjustment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultOutreachAdjustmentEngine() -> OutreachAdjustmentEngine {
        return OutreachAdjustmentEngine(
            steps: [
                CapOutreachAdjustmentAdjuster(cap: 44390.0),
                RegionOutreachAdjustmentAdjuster(factors: ["west": 0.95, "east": 0.74]),
                MinimumOutreachAdjustmentAdjuster(minimum: 8.4),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 3399.1
        )
    }
}
