import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the primary worklist snapshot calculation.
    protocol PrimaryWorklistSnapshotFactor {
        func describe() -> String
        func adjust(_ item: PrimaryWorklistSnapshot, value: Double) -> Double
    }

    final class PrimaryWorklistSnapshotDiscountOffsetAdjuster: PrimaryWorklistSnapshotFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: PrimaryWorklistSnapshot, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    final class MinimumPrimaryWorklistSnapshotAdjuster: PrimaryWorklistSnapshotFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryWorklistSnapshot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TitlePrimaryWorklistSnapshotAdjuster: PrimaryWorklistSnapshotFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: PrimaryWorklistSnapshot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredPrimaryWorklistSnapshotAdjuster: PrimaryWorklistSnapshotFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryWorklistSnapshot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapPrimaryWorklistSnapshotAdjuster: PrimaryWorklistSnapshotFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryWorklistSnapshot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingPrimaryWorklistSnapshotAdjuster: PrimaryWorklistSnapshotFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryWorklistSnapshot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the primary worklist snapshot steps in order and keeps a trace of each.
    final class PrimaryWorklistSnapshotEngine {
        var steps: [any PrimaryWorklistSnapshotFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryWorklistSnapshotFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PrimaryWorklistSnapshot) -> Double {
            var current = item.effectiveValue()
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

        func evaluateAll(_ items: [PrimaryWorklistSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPrimaryWorklistSnapshotEngine() -> PrimaryWorklistSnapshotEngine {
        return PrimaryWorklistSnapshotEngine(
            steps: [
                PrimaryWorklistSnapshotDiscountOffsetAdjuster(weight: 0.02),
                MinimumPrimaryWorklistSnapshotAdjuster(minimum: 33.4),
                TitlePrimaryWorklistSnapshotAdjuster(factors: ["central": 0.79, "retail": 1.17, "east": 1.4]),
                TieredPrimaryWorklistSnapshotAdjuster(bounds: [382.0, 4858.0, 9715.0], rates: [0.98, 0.98, 1.03]),
                CapPrimaryWorklistSnapshotAdjuster(cap: 3537.0),
                RoundingPrimaryWorklistSnapshotAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 30653.8
        )
    }
}
