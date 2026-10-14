import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the care protocol digest calculation.
    protocol CareProtocolDigestAdjuster {
        func describe() -> String
        func adjust(_ item: CareProtocolDigest, value: Double) -> Double
    }

    final class PercentCareProtocolDigestAdjuster: CareProtocolDigestAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CareProtocolDigest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumCareProtocolDigestAdjuster: CareProtocolDigestAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CareProtocolDigest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CareProtocolDigestAmountOffsetAdjuster: CareProtocolDigestAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: CareProtocolDigest, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class FlaggedCareProtocolDigestAdjuster: CareProtocolDigestAdjuster {
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

        func adjust(_ item: CareProtocolDigest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelCareProtocolDigestAdjuster: CareProtocolDigestAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: CareProtocolDigest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredCareProtocolDigestAdjuster: CareProtocolDigestAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CareProtocolDigest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the care protocol digest steps in order and keeps a trace of each.
    final class CareProtocolDigestEngine {
        var steps: [any CareProtocolDigestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareProtocolDigestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CareProtocolDigest) -> Double {
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

        func evaluateAll(_ items: [CareProtocolDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCareProtocolDigestEngine(_ flags: Kit.Flags.Registry) -> CareProtocolDigestEngine {
        return CareProtocolDigestEngine(
            steps: [
                PercentCareProtocolDigestAdjuster(percent: 8.4),
                MinimumCareProtocolDigestAdjuster(minimum: 20.6),
                CareProtocolDigestAmountOffsetAdjuster(weight: 0.48),
                FlaggedCareProtocolDigestAdjuster(flags: flags, flag: "care-protocol-digest-capped", percent: -1.6),
                LabelCareProtocolDigestAdjuster(factors: ["central": 1.12]),
                TieredCareProtocolDigestAdjuster(bounds: [2877.0, 5267.0], rates: [1.07, 0.86]),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 98011.6
        )
    }
}
