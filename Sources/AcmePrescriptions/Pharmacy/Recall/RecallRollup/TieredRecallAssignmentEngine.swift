import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the tiered recall assignment calculation.
    protocol TieredRecallAssignmentFactor {
        func describe() -> String
        func adjust(_ item: TieredRecallAssignment, value: Double) -> Double
    }

    final class CategoryTieredRecallAssignmentAdjuster: TieredRecallAssignmentFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: TieredRecallAssignment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapTieredRecallAssignmentAdjuster: TieredRecallAssignmentFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredRecallAssignment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredRecallAssignmentWindowDaysOffsetAdjuster: TieredRecallAssignmentFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: TieredRecallAssignment, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    /// Runs the tiered recall assignment steps in order and keeps a trace of each.
    final class TieredRecallAssignmentEngine {
        var steps: [any TieredRecallAssignmentFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredRecallAssignmentFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: TieredRecallAssignment) -> Double {
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

        func evaluateAll(_ items: [TieredRecallAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultTieredRecallAssignmentEngine() -> TieredRecallAssignmentEngine {
        return TieredRecallAssignmentEngine(
            steps: [
                CategoryTieredRecallAssignmentAdjuster(factors: ["south": 0.86]),
                CapTieredRecallAssignmentAdjuster(cap: 23331.0),
                TieredRecallAssignmentWindowDaysOffsetAdjuster(weight: 1.39),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 48368.5
        )
    }
}
