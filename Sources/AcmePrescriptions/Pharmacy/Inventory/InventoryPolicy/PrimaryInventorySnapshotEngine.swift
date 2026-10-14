import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the primary inventory snapshot calculation.
    protocol PrimaryInventorySnapshotAdjuster {
        func describe() -> String
        func adjust(_ item: PrimaryInventorySnapshot, value: Double) -> Double
    }

    final class MinimumPrimaryInventorySnapshotAdjuster: PrimaryInventorySnapshotAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryInventorySnapshot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredPrimaryInventorySnapshotAdjuster: PrimaryInventorySnapshotAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryInventorySnapshot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentPrimaryInventorySnapshotAdjuster: PrimaryInventorySnapshotAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryInventorySnapshot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the primary inventory snapshot steps in order and keeps a trace of each.
    final class PrimaryInventorySnapshotEngine {
        var steps: [any PrimaryInventorySnapshotAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryInventorySnapshotAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PrimaryInventorySnapshot) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimaryInventorySnapshotAdjuster = steps[index]
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

        func evaluateAll(_ items: [PrimaryInventorySnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPrimaryInventorySnapshotEngine() -> PrimaryInventorySnapshotEngine {
        return PrimaryInventorySnapshotEngine(
            steps: [
                MinimumPrimaryInventorySnapshotAdjuster(minimum: 22.6),
                TieredPrimaryInventorySnapshotAdjuster(
                    bounds: [832.0, 911.0, 4136.0, 5079.0],
                    rates: [1.05, 0.82, 0.82, 0.82]
                ),
                PercentPrimaryInventorySnapshotAdjuster(percent: -16.9),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 52392.7
        )
    }
}
