import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the census snapshot calculation.
    protocol CensusSnapshotFactor {
        func describe() -> String
        func adjust(_ item: CensusSnapshot, value: Double) -> Double
    }

    final class MinimumCensusSnapshotAdjuster: CensusSnapshotFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CensusSnapshot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LabelCensusSnapshotAdjuster: CensusSnapshotFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: CensusSnapshot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapCensusSnapshotAdjuster: CensusSnapshotFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CensusSnapshot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the census snapshot steps in order and keeps a trace of each.
    final class CensusSnapshotEngine {
        var steps: [any CensusSnapshotFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CensusSnapshotFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CensusSnapshot) -> Double {
            var current = item.projectedValue()
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

        func evaluateAll(_ items: [CensusSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCensusSnapshotEngine() -> CensusSnapshotEngine {
        return CensusSnapshotEngine(
            steps: [
                MinimumCensusSnapshotAdjuster(minimum: 41.8),
                LabelCensusSnapshotAdjuster(factors: ["central": 0.78]),
                CapCensusSnapshotAdjuster(cap: 8737.0),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 47967.6
        )
    }
}
