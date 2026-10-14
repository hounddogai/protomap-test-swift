import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the formulary record calculation.
    protocol FormularyRecordAdjuster {
        func describe() -> String
        func adjust(_ item: FormularyRecord, value: Double) -> Double
    }

    final class SourceFormularyRecordAdjuster: FormularyRecordAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: FormularyRecord, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumFormularyRecordAdjuster: FormularyRecordAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FormularyRecord, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapFormularyRecordAdjuster: FormularyRecordAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FormularyRecord, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the formulary record steps in order and keeps a trace of each.
    final class FormularyRecordEngine {
        var steps: [any FormularyRecordAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FormularyRecordAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FormularyRecord) -> Double {
            var current = item.adjustedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any FormularyRecordAdjuster = steps[index]
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

        func evaluateAll(_ items: [FormularyRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFormularyRecordEngine() -> FormularyRecordEngine {
        return FormularyRecordEngine(
            steps: [
                SourceFormularyRecordAdjuster(factors: ["retail": 1.09, "central": 0.84]),
                MinimumFormularyRecordAdjuster(minimum: 36.5),
                CapFormularyRecordAdjuster(cap: 7145.0),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 99564.3
        )
    }
}
