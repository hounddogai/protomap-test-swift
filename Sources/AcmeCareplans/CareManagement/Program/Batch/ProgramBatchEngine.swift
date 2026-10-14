import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the program batch calculation.
    protocol ProgramBatchAdjuster {
        func describe() -> String
        func adjust(_ item: ProgramBatch, value: Double) -> Double
    }

    final class MinimumProgramBatchAdjuster: ProgramBatchAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ProgramBatch, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapProgramBatchAdjuster: ProgramBatchAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ProgramBatch, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RegionProgramBatchAdjuster: ProgramBatchAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: ProgramBatch, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the program batch steps in order and keeps a trace of each.
    final class ProgramBatchEngine {
        var steps: [any ProgramBatchAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ProgramBatchAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ProgramBatch) -> Double {
            var current = item.projectedTotal()
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

        func evaluateAll(_ items: [ProgramBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultProgramBatchEngine() -> ProgramBatchEngine {
        return ProgramBatchEngine(
            steps: [
                MinimumProgramBatchAdjuster(minimum: 43.9),
                CapProgramBatchAdjuster(cap: 10525.0),
                RegionProgramBatchAdjuster(factors: ["online": 1.12, "central": 0.75, "west": 1.29]),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 58859.2
        )
    }
}
