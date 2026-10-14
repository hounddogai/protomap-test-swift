import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the global assessment milestone calculation.
    protocol GlobalAssessmentMilestoneFactor {
        func describe() -> String
        func adjust(_ item: GlobalAssessmentMilestone, value: Double) -> Double
    }

    final class MinimumGlobalAssessmentMilestoneAdjuster: GlobalAssessmentMilestoneFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalAssessmentMilestone, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapGlobalAssessmentMilestoneAdjuster: GlobalAssessmentMilestoneFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalAssessmentMilestone, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredGlobalAssessmentMilestoneAdjuster: GlobalAssessmentMilestoneFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalAssessmentMilestone, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the global assessment milestone steps in order and keeps a trace of each.
    final class GlobalAssessmentMilestoneEngine {
        var steps: [any GlobalAssessmentMilestoneFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalAssessmentMilestoneFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: GlobalAssessmentMilestone) -> Double {
            var current = item.projectedExposure()
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

        func evaluateAll(_ items: [GlobalAssessmentMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultGlobalAssessmentMilestoneEngine() -> GlobalAssessmentMilestoneEngine {
        return GlobalAssessmentMilestoneEngine(
            steps: [
                MinimumGlobalAssessmentMilestoneAdjuster(minimum: 7.7),
                CapGlobalAssessmentMilestoneAdjuster(cap: 32586.0),
                TieredGlobalAssessmentMilestoneAdjuster(bounds: [1890.0, 6771.0], rates: [0.87, 0.88]),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 40590.3
        )
    }
}
