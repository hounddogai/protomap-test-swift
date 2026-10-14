import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the overtime batch calculation.
    protocol OvertimeBatchStep {
        func describe() -> String
        func adjust(_ item: OvertimeBatch, value: Double) -> Double
    }

    final class OvertimeBatchCeilingOffsetAdjuster: OvertimeBatchStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ceiling times \(weight)"
        }

        func adjust(_ item: OvertimeBatch, value: Double) -> Double {
            return value + item.ceiling * weight
        }
    }

    final class PercentOvertimeBatchAdjuster: OvertimeBatchStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: OvertimeBatch, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapOvertimeBatchAdjuster: OvertimeBatchStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: OvertimeBatch, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the overtime batch steps in order and keeps a trace of each.
    final class OvertimeBatchEngine {
        var steps: [any OvertimeBatchStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OvertimeBatchStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: OvertimeBatch) -> Double {
            var current = item.weightedValue()
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

        func evaluateAll(_ items: [OvertimeBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultOvertimeBatchEngine() -> OvertimeBatchEngine {
        return OvertimeBatchEngine(
            steps: [
                OvertimeBatchCeilingOffsetAdjuster(weight: 0.38),
                PercentOvertimeBatchAdjuster(percent: -15.0),
                CapOvertimeBatchAdjuster(cap: 21167.0),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 36226.6
        )
    }
}
