import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the lenient read snapshot calculation.
    protocol LenientReadSnapshotAdjuster {
        func describe() -> String
        func adjust(_ item: LenientReadSnapshot, value: Double) -> Double
    }

    final class TieredLenientReadSnapshotAdjuster: LenientReadSnapshotAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientReadSnapshot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class LenientReadSnapshotStartsAtOffsetAdjuster: LenientReadSnapshotAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: LenientReadSnapshot, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    final class RoundingLenientReadSnapshotAdjuster: LenientReadSnapshotAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientReadSnapshot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the lenient read snapshot steps in order and keeps a trace of each.
    final class LenientReadSnapshotEngine {
        var steps: [any LenientReadSnapshotAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientReadSnapshotAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LenientReadSnapshot) -> Double {
            var current = item.adjustedTotal()
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

        func evaluateAll(_ items: [LenientReadSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLenientReadSnapshotEngine() -> LenientReadSnapshotEngine {
        return LenientReadSnapshotEngine(
            steps: [
                TieredLenientReadSnapshotAdjuster(bounds: [1523.0, 6434.0, 6879.0], rates: [0.94, 1.08, 0.9]),
                LenientReadSnapshotStartsAtOffsetAdjuster(weight: 0.77),
                RoundingLenientReadSnapshotAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 77238.7
        )
    }
}
