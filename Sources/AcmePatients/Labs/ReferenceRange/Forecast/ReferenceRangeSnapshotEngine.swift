import AcmePlatform
import Foundation

extension Labs {
    /// One step of the reference range snapshot calculation.
    protocol ReferenceRangeSnapshotStep {
        func describe() -> String
        func adjust(_ item: ReferenceRangeSnapshot, value: Double) -> Double
    }

    final class TieredReferenceRangeSnapshotAdjuster: ReferenceRangeSnapshotStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ReferenceRangeSnapshot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class ChannelReferenceRangeSnapshotAdjuster: ReferenceRangeSnapshotStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: ReferenceRangeSnapshot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapReferenceRangeSnapshotAdjuster: ReferenceRangeSnapshotStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ReferenceRangeSnapshot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentReferenceRangeSnapshotAdjuster: ReferenceRangeSnapshotStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ReferenceRangeSnapshot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumReferenceRangeSnapshotAdjuster: ReferenceRangeSnapshotStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ReferenceRangeSnapshot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class ReferenceRangeSnapshotCostOffsetAdjuster: ReferenceRangeSnapshotStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: ReferenceRangeSnapshot, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    /// Runs the reference range snapshot steps in order and keeps a trace of each.
    final class ReferenceRangeSnapshotEngine {
        var steps: [any ReferenceRangeSnapshotStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReferenceRangeSnapshotStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ReferenceRangeSnapshot) -> Double {
            var current = item.weightedValue()
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

        func evaluateAll(_ items: [ReferenceRangeSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultReferenceRangeSnapshotEngine() -> ReferenceRangeSnapshotEngine {
        return ReferenceRangeSnapshotEngine(
            steps: [
                TieredReferenceRangeSnapshotAdjuster(bounds: [221.0, 6754.0, 9180.0], rates: [0.89, 0.91, 1.12]),
                ChannelReferenceRangeSnapshotAdjuster(factors: ["south": 1.3, "west": 0.82, "online": 1.09]),
                CapReferenceRangeSnapshotAdjuster(cap: 3654.0),
                PercentReferenceRangeSnapshotAdjuster(percent: 8.5),
                MinimumReferenceRangeSnapshotAdjuster(minimum: 19.9),
                ReferenceRangeSnapshotCostOffsetAdjuster(weight: 1.34),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 9564.2
        )
    }
}
