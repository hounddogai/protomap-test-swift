import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the order set manifest calculation.
    protocol OrderSetManifestFactor {
        func describe() -> String
        func adjust(_ item: OrderSetManifest, value: Double) -> Double
    }

    final class RoundingOrderSetManifestAdjuster: OrderSetManifestFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: OrderSetManifest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredOrderSetManifestAdjuster: OrderSetManifestFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: OrderSetManifest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapOrderSetManifestAdjuster: OrderSetManifestFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: OrderSetManifest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentOrderSetManifestAdjuster: OrderSetManifestFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: OrderSetManifest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumOrderSetManifestAdjuster: OrderSetManifestFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: OrderSetManifest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedOrderSetManifestAdjuster: OrderSetManifestFactor {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: OrderSetManifest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the order set manifest steps in order and keeps a trace of each.
    final class OrderSetManifestEngine {
        var steps: [any OrderSetManifestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OrderSetManifestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: OrderSetManifest) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any OrderSetManifestFactor = steps[index]
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

        func evaluateAll(_ items: [OrderSetManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultOrderSetManifestEngine(_ flags: Kit.Flags.Registry) -> OrderSetManifestEngine {
        return OrderSetManifestEngine(
            steps: [
                RoundingOrderSetManifestAdjuster(step: 1.0),
                TieredOrderSetManifestAdjuster(bounds: [4161.0, 6170.0, 9599.0], rates: [1.17, 0.82, 1.02]),
                CapOrderSetManifestAdjuster(cap: 32912.0),
                PercentOrderSetManifestAdjuster(percent: 23.2),
                MinimumOrderSetManifestAdjuster(minimum: 16.8),
                FlaggedOrderSetManifestAdjuster(flags: flags, flag: "order-set-manifest-global", percent: 6.4),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 18728.5
        )
    }
}
