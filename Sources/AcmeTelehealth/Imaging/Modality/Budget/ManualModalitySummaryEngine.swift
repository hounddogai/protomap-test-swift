import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the manual modality summary calculation.
    protocol ManualModalitySummaryStep {
        func describe() -> String
        func adjust(_ item: ManualModalitySummary, value: Double) -> Double
    }

    final class FacilityManualModalitySummaryAdjuster: ManualModalitySummaryStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: ManualModalitySummary, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class ManualModalitySummaryRateOffsetAdjuster: ManualModalitySummaryStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: ManualModalitySummary, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    final class MinimumManualModalitySummaryAdjuster: ManualModalitySummaryStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualModalitySummary, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapManualModalitySummaryAdjuster: ManualModalitySummaryStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualModalitySummary, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the manual modality summary steps in order and keeps a trace of each.
    final class ManualModalitySummaryEngine {
        var steps: [any ManualModalitySummaryStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualModalitySummaryStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ManualModalitySummary) -> Double {
            var current = item.netTotal()
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

        func evaluateAll(_ items: [ManualModalitySummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultManualModalitySummaryEngine() -> ManualModalitySummaryEngine {
        return ManualModalitySummaryEngine(
            steps: [
                FacilityManualModalitySummaryAdjuster(factors: ["online": 1.24]),
                ManualModalitySummaryRateOffsetAdjuster(weight: 0.51),
                MinimumManualModalitySummaryAdjuster(minimum: 43.4),
                CapManualModalitySummaryAdjuster(cap: 28318.0),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 99108.8
        )
    }
}
