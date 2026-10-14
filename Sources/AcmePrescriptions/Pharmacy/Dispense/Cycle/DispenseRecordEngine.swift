import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the dispense record calculation.
    protocol DispenseRecordFactor {
        func describe() -> String
        func adjust(_ item: DispenseRecord, value: Double) -> Double
    }

    final class MinimumDispenseRecordAdjuster: DispenseRecordFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DispenseRecord, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class NameDispenseRecordAdjuster: DispenseRecordFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: DispenseRecord, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class DispenseRecordCopayOffsetAdjuster: DispenseRecordFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: DispenseRecord, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    /// Runs the dispense record steps in order and keeps a trace of each.
    final class DispenseRecordEngine {
        var steps: [any DispenseRecordFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DispenseRecordFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DispenseRecord) -> Double {
            var current = item.adjustedValue()
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

        func evaluateAll(_ items: [DispenseRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDispenseRecordEngine() -> DispenseRecordEngine {
        return DispenseRecordEngine(
            steps: [
                MinimumDispenseRecordAdjuster(minimum: 29.8),
                NameDispenseRecordAdjuster(factors: ["north": 0.96, "south": 0.9, "east": 1.24]),
                DispenseRecordCopayOffsetAdjuster(weight: 0.64),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 34117.6
        )
    }
}
