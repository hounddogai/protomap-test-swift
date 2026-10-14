import AcmePlatform
import Foundation

extension Labs {
    /// One step of the global courier milestone calculation.
    protocol GlobalCourierMilestoneAdjuster {
        func describe() -> String
        func adjust(_ item: GlobalCourierMilestone, value: Double) -> Double
    }

    final class TieredGlobalCourierMilestoneAdjuster: GlobalCourierMilestoneAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalCourierMilestone, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentGlobalCourierMilestoneAdjuster: GlobalCourierMilestoneAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalCourierMilestone, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SourceGlobalCourierMilestoneAdjuster: GlobalCourierMilestoneAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: GlobalCourierMilestone, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class GlobalCourierMilestoneDosageMgOffsetAdjuster: GlobalCourierMilestoneAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus dosage mg times \(weight)"
        }

        func adjust(_ item: GlobalCourierMilestone, value: Double) -> Double {
            return value + item.dosageMg * weight
        }
    }

    final class CapGlobalCourierMilestoneAdjuster: GlobalCourierMilestoneAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalCourierMilestone, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the global courier milestone steps in order and keeps a trace of each.
    final class GlobalCourierMilestoneEngine {
        var steps: [any GlobalCourierMilestoneAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalCourierMilestoneAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: GlobalCourierMilestone) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalCourierMilestoneAdjuster = steps[index]
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

        func evaluateAll(_ items: [GlobalCourierMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultGlobalCourierMilestoneEngine() -> GlobalCourierMilestoneEngine {
        return GlobalCourierMilestoneEngine(
            steps: [
                TieredGlobalCourierMilestoneAdjuster(
                    bounds: [1344.0, 4303.0, 4653.0, 6540.0],
                    rates: [0.82, 0.91, 0.99, 0.9]
                ),
                PercentGlobalCourierMilestoneAdjuster(percent: 4.0),
                SourceGlobalCourierMilestoneAdjuster(factors: ["retail": 1.38, "online": 0.98]),
                GlobalCourierMilestoneDosageMgOffsetAdjuster(weight: 0.46),
                CapGlobalCourierMilestoneAdjuster(cap: 39856.0),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 24207.3
        )
    }
}
