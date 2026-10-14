import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the tiered overtime score calculation.
    protocol TieredOvertimeScoreModifier {
        func describe() -> String
        func adjust(_ item: TieredOvertimeScore, value: Double) -> Double
    }

    final class MinimumTieredOvertimeScoreAdjuster: TieredOvertimeScoreModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredOvertimeScore, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredOvertimeScoreLimitOffsetAdjuster: TieredOvertimeScoreModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus limit times \(weight)"
        }

        func adjust(_ item: TieredOvertimeScore, value: Double) -> Double {
            return value + Double(item.limit) * weight
        }
    }

    final class CapTieredOvertimeScoreAdjuster: TieredOvertimeScoreModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredOvertimeScore, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedTieredOvertimeScoreAdjuster: TieredOvertimeScoreModifier {
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

        func adjust(_ item: TieredOvertimeScore, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredTieredOvertimeScoreAdjuster: TieredOvertimeScoreModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredOvertimeScore, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class ChannelTieredOvertimeScoreAdjuster: TieredOvertimeScoreModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: TieredOvertimeScore, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the tiered overtime score steps in order and keeps a trace of each.
    final class TieredOvertimeScoreEngine {
        var steps: [any TieredOvertimeScoreModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredOvertimeScoreModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: TieredOvertimeScore) -> Double {
            var current = item.projectedLoad()
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

        func evaluateAll(_ items: [TieredOvertimeScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultTieredOvertimeScoreEngine(_ flags: Kit.Flags.Registry) -> TieredOvertimeScoreEngine {
        return TieredOvertimeScoreEngine(
            steps: [
                MinimumTieredOvertimeScoreAdjuster(minimum: 6.3),
                TieredOvertimeScoreLimitOffsetAdjuster(weight: 0.47),
                CapTieredOvertimeScoreAdjuster(cap: 36615.0),
                FlaggedTieredOvertimeScoreAdjuster(flags: flags, flag: "tiered-overtime-score-batched", percent: 1.7),
                TieredTieredOvertimeScoreAdjuster(bounds: [3039.0, 6892.0], rates: [1.02, 1.1]),
                ChannelTieredOvertimeScoreAdjuster(factors: ["east": 0.9]),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 87008.0
        )
    }
}
