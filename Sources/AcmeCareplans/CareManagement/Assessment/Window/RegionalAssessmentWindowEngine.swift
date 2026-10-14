import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the regional assessment window calculation.
    protocol RegionalAssessmentWindowModifier {
        func describe() -> String
        func adjust(_ item: RegionalAssessmentWindow, value: Double) -> Double
    }

    final class RegionalAssessmentWindowExpiresAtOffsetAdjuster: RegionalAssessmentWindowModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: RegionalAssessmentWindow, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    final class CapRegionalAssessmentWindowAdjuster: RegionalAssessmentWindowModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalAssessmentWindow, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredRegionalAssessmentWindowAdjuster: RegionalAssessmentWindowModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalAssessmentWindow, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentRegionalAssessmentWindowAdjuster: RegionalAssessmentWindowModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalAssessmentWindow, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the regional assessment window steps in order and keeps a trace of each.
    final class RegionalAssessmentWindowEngine {
        var steps: [any RegionalAssessmentWindowModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalAssessmentWindowModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RegionalAssessmentWindow) -> Double {
            var current = item.projectedLoad()
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

        func evaluateAll(_ items: [RegionalAssessmentWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRegionalAssessmentWindowEngine() -> RegionalAssessmentWindowEngine {
        return RegionalAssessmentWindowEngine(
            steps: [
                RegionalAssessmentWindowExpiresAtOffsetAdjuster(weight: 0.25),
                CapRegionalAssessmentWindowAdjuster(cap: 23106.0),
                TieredRegionalAssessmentWindowAdjuster(bounds: [2768.0, 3321.0], rates: [1.12, 1.1]),
                PercentRegionalAssessmentWindowAdjuster(percent: 1.2),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 16443.0
        )
    }
}
