import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the fallback census snapshot calculation.
    protocol FallbackCensusSnapshotStep {
        func describe() -> String
        func adjust(_ item: FallbackCensusSnapshot, value: Double) -> Double
    }

    final class CapFallbackCensusSnapshotAdjuster: FallbackCensusSnapshotStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackCensusSnapshot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class NameFallbackCensusSnapshotAdjuster: FallbackCensusSnapshotStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: FallbackCensusSnapshot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingFallbackCensusSnapshotAdjuster: FallbackCensusSnapshotStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackCensusSnapshot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FallbackCensusSnapshotAttemptsOffsetAdjuster: FallbackCensusSnapshotStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: FallbackCensusSnapshot, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    final class MinimumFallbackCensusSnapshotAdjuster: FallbackCensusSnapshotStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackCensusSnapshot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the fallback census snapshot steps in order and keeps a trace of each.
    final class FallbackCensusSnapshotEngine {
        var steps: [any FallbackCensusSnapshotStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackCensusSnapshotStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: FallbackCensusSnapshot) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [FallbackCensusSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultFallbackCensusSnapshotEngine() -> FallbackCensusSnapshotEngine {
        return FallbackCensusSnapshotEngine(
            steps: [
                CapFallbackCensusSnapshotAdjuster(cap: 30899.0),
                NameFallbackCensusSnapshotAdjuster(factors: ["north": 0.93]),
                RoundingFallbackCensusSnapshotAdjuster(step: 5.0),
                FallbackCensusSnapshotAttemptsOffsetAdjuster(weight: 0.66),
                MinimumFallbackCensusSnapshotAdjuster(minimum: 7.9),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 58271.6
        )
    }
}
