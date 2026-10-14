import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the formulary batch calculation.
    protocol FormularyBatchStep {
        func describe() -> String
        func adjust(_ item: FormularyBatch, value: Double) -> Double
    }

    final class CapFormularyBatchAdjuster: FormularyBatchStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FormularyBatch, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedFormularyBatchAdjuster: FormularyBatchStep {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: FormularyBatch, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredFormularyBatchAdjuster: FormularyBatchStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FormularyBatch, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the formulary batch steps in order and keeps a trace of each.
    final class FormularyBatchEngine {
        var steps: [any FormularyBatchStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FormularyBatchStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: FormularyBatch) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any FormularyBatchStep = steps[index]
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

        func evaluateAll(_ items: [FormularyBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultFormularyBatchEngine(_ flags: Kit.Flags.Registry) -> FormularyBatchEngine {
        return FormularyBatchEngine(
            steps: [
                CapFormularyBatchAdjuster(cap: 17849.0),
                FlaggedFormularyBatchAdjuster(flags: flags, flag: "formulary-batch-manual", percent: -1.9),
                TieredFormularyBatchAdjuster(
                    bounds: [1628.0, 1639.0, 4933.0, 9509.0],
                    rates: [0.92, 0.86, 1.19, 1.16]
                ),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 11236.6
        )
    }
}
