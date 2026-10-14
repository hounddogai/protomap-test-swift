import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the primary network bundle calculation.
    protocol PrimaryNetworkBundleStep {
        func describe() -> String
        func adjust(_ item: PrimaryNetworkBundle, value: Double) -> Double
    }

    final class PrimaryNetworkBundleMarginOffsetAdjuster: PrimaryNetworkBundleStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus margin times \(weight)"
        }

        func adjust(_ item: PrimaryNetworkBundle, value: Double) -> Double {
            return value + item.margin * weight
        }
    }

    final class MinimumPrimaryNetworkBundleAdjuster: PrimaryNetworkBundleStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryNetworkBundle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingPrimaryNetworkBundleAdjuster: PrimaryNetworkBundleStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryNetworkBundle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentPrimaryNetworkBundleAdjuster: PrimaryNetworkBundleStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryNetworkBundle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapPrimaryNetworkBundleAdjuster: PrimaryNetworkBundleStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryNetworkBundle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class CountryPrimaryNetworkBundleAdjuster: PrimaryNetworkBundleStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: PrimaryNetworkBundle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the primary network bundle steps in order and keeps a trace of each.
    final class PrimaryNetworkBundleEngine {
        var steps: [any PrimaryNetworkBundleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryNetworkBundleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PrimaryNetworkBundle) -> Double {
            var current = item.effectiveLoad()
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

        func evaluateAll(_ items: [PrimaryNetworkBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPrimaryNetworkBundleEngine() -> PrimaryNetworkBundleEngine {
        return PrimaryNetworkBundleEngine(
            steps: [
                PrimaryNetworkBundleMarginOffsetAdjuster(weight: 0.6),
                MinimumPrimaryNetworkBundleAdjuster(minimum: 11.9),
                RoundingPrimaryNetworkBundleAdjuster(step: 0.1),
                PercentPrimaryNetworkBundleAdjuster(percent: -13.9),
                CapPrimaryNetworkBundleAdjuster(cap: 10754.0),
                CountryPrimaryNetworkBundleAdjuster(factors: ["south": 0.79]),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 31230.3
        )
    }
}
