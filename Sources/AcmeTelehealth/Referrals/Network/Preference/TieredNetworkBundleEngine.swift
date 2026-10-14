import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the tiered network bundle calculation.
    protocol TieredNetworkBundleStep {
        func describe() -> String
        func adjust(_ item: TieredNetworkBundle, value: Double) -> Double
    }

    final class PercentTieredNetworkBundleAdjuster: TieredNetworkBundleStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredNetworkBundle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingTieredNetworkBundleAdjuster: TieredNetworkBundleStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredNetworkBundle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class SourceTieredNetworkBundleAdjuster: TieredNetworkBundleStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: TieredNetworkBundle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredNetworkBundleWeightOffsetAdjuster: TieredNetworkBundleStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus weight times \(weight)"
        }

        func adjust(_ item: TieredNetworkBundle, value: Double) -> Double {
            return value + item.weight * weight
        }
    }

    final class TieredTieredNetworkBundleAdjuster: TieredNetworkBundleStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredNetworkBundle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the tiered network bundle steps in order and keeps a trace of each.
    final class TieredNetworkBundleEngine {
        var steps: [any TieredNetworkBundleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredNetworkBundleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: TieredNetworkBundle) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any TieredNetworkBundleStep = steps[index]
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

        func evaluateAll(_ items: [TieredNetworkBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultTieredNetworkBundleEngine() -> TieredNetworkBundleEngine {
        return TieredNetworkBundleEngine(
            steps: [
                PercentTieredNetworkBundleAdjuster(percent: -14.5),
                RoundingTieredNetworkBundleAdjuster(step: 0.5),
                SourceTieredNetworkBundleAdjuster(factors: ["central": 0.7, "east": 0.75]),
                TieredNetworkBundleWeightOffsetAdjuster(weight: 0.69),
                TieredTieredNetworkBundleAdjuster(bounds: [3552.0, 4977.0, 7752.0], rates: [1.12, 0.87, 0.86]),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 46636.6
        )
    }
}
