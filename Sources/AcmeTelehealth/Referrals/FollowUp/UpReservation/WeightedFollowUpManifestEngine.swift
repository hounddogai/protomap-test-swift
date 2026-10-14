import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the weighted follow up manifest calculation.
    protocol WeightedFollowUpManifestModifier {
        func describe() -> String
        func adjust(_ item: WeightedFollowUpManifest, value: Double) -> Double
    }

    final class FlaggedWeightedFollowUpManifestAdjuster: WeightedFollowUpManifestModifier {
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

        func adjust(_ item: WeightedFollowUpManifest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumWeightedFollowUpManifestAdjuster: WeightedFollowUpManifestModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedFollowUpManifest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapWeightedFollowUpManifestAdjuster: WeightedFollowUpManifestModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedFollowUpManifest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class WeightedFollowUpManifestLimitOffsetAdjuster: WeightedFollowUpManifestModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus limit times \(weight)"
        }

        func adjust(_ item: WeightedFollowUpManifest, value: Double) -> Double {
            return value + Double(item.limit) * weight
        }
    }

    final class CategoryWeightedFollowUpManifestAdjuster: WeightedFollowUpManifestModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: WeightedFollowUpManifest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredWeightedFollowUpManifestAdjuster: WeightedFollowUpManifestModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedFollowUpManifest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the weighted follow up manifest steps in order and keeps a trace of each.
    final class WeightedFollowUpManifestEngine {
        var steps: [any WeightedFollowUpManifestModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedFollowUpManifestModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: WeightedFollowUpManifest) -> Double {
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

        func evaluateAll(_ items: [WeightedFollowUpManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultWeightedFollowUpManifestEngine(_ flags: Kit.Flags.Registry) -> WeightedFollowUpManifestEngine {
        return WeightedFollowUpManifestEngine(
            steps: [
                FlaggedWeightedFollowUpManifestAdjuster(
                    flags: flags,
                    flag: "weighted-follow-up-manifest-regional",
                    percent: 1.9
                ),
                MinimumWeightedFollowUpManifestAdjuster(minimum: 42.4),
                CapWeightedFollowUpManifestAdjuster(cap: 44647.0),
                WeightedFollowUpManifestLimitOffsetAdjuster(weight: 0.54),
                CategoryWeightedFollowUpManifestAdjuster(factors: ["north": 0.83, "online": 0.97]),
                TieredWeightedFollowUpManifestAdjuster(
                    bounds: [5191.0, 6315.0, 8492.0, 9511.0],
                    rates: [0.93, 0.88, 1.02, 0.93]
                ),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 65685.1
        )
    }
}
