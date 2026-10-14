import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the lenient order set snapshot calculation.
    protocol LenientOrderSetSnapshotAdjuster {
        func describe() -> String
        func adjust(_ item: LenientOrderSetSnapshot, value: Double) -> Double
    }

    final class RoundingLenientOrderSetSnapshotAdjuster: LenientOrderSetSnapshotAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientOrderSetSnapshot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapLenientOrderSetSnapshotAdjuster: LenientOrderSetSnapshotAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientOrderSetSnapshot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredLenientOrderSetSnapshotAdjuster: LenientOrderSetSnapshotAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientOrderSetSnapshot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentLenientOrderSetSnapshotAdjuster: LenientOrderSetSnapshotAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientOrderSetSnapshot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SegmentLenientOrderSetSnapshotAdjuster: LenientOrderSetSnapshotAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: LenientOrderSetSnapshot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumLenientOrderSetSnapshotAdjuster: LenientOrderSetSnapshotAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientOrderSetSnapshot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the lenient order set snapshot steps in order and keeps a trace of each.
    final class LenientOrderSetSnapshotEngine {
        var steps: [any LenientOrderSetSnapshotAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientOrderSetSnapshotAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LenientOrderSetSnapshot) -> Double {
            var current = item.netTotal()
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

        func evaluateAll(_ items: [LenientOrderSetSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLenientOrderSetSnapshotEngine() -> LenientOrderSetSnapshotEngine {
        return LenientOrderSetSnapshotEngine(
            steps: [
                RoundingLenientOrderSetSnapshotAdjuster(step: 0.1),
                CapLenientOrderSetSnapshotAdjuster(cap: 17021.0),
                TieredLenientOrderSetSnapshotAdjuster(
                    bounds: [2568.0, 5063.0, 5414.0, 9821.0],
                    rates: [1.09, 1.05, 0.86, 1.16]
                ),
                PercentLenientOrderSetSnapshotAdjuster(percent: -18.9),
                SegmentLenientOrderSetSnapshotAdjuster(factors: ["south": 0.91, "retail": 0.87, "online": 1.12]),
                MinimumLenientOrderSetSnapshotAdjuster(minimum: 20.9),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 59902.8
        )
    }
}
