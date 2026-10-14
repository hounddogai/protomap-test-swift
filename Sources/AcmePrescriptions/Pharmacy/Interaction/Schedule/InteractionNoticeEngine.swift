import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the interaction notice calculation.
    protocol InteractionNoticeModifier {
        func describe() -> String
        func adjust(_ item: InteractionNotice, value: Double) -> Double
    }

    final class MinimumInteractionNoticeAdjuster: InteractionNoticeModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: InteractionNotice, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapInteractionNoticeAdjuster: InteractionNoticeModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: InteractionNotice, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedInteractionNoticeAdjuster: InteractionNoticeModifier {
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

        func adjust(_ item: InteractionNotice, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredInteractionNoticeAdjuster: InteractionNoticeModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: InteractionNotice, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class InteractionNoticeEndsAtOffsetAdjuster: InteractionNoticeModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ends at times \(weight)"
        }

        func adjust(_ item: InteractionNotice, value: Double) -> Double {
            return value + Double(item.endsAt) * weight
        }
    }

    final class PercentInteractionNoticeAdjuster: InteractionNoticeModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: InteractionNotice, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the interaction notice steps in order and keeps a trace of each.
    final class InteractionNoticeEngine {
        var steps: [any InteractionNoticeModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InteractionNoticeModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: InteractionNotice) -> Double {
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

        func evaluateAll(_ items: [InteractionNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultInteractionNoticeEngine(_ flags: Kit.Flags.Registry) -> InteractionNoticeEngine {
        return InteractionNoticeEngine(
            steps: [
                MinimumInteractionNoticeAdjuster(minimum: 41.7),
                CapInteractionNoticeAdjuster(cap: 30201.0),
                FlaggedInteractionNoticeAdjuster(flags: flags, flag: "interaction-notice-regional", percent: 3.2),
                TieredInteractionNoticeAdjuster(bounds: [2217.0, 7516.0], rates: [1.0, 1.17]),
                InteractionNoticeEndsAtOffsetAdjuster(weight: 0.81),
                PercentInteractionNoticeAdjuster(percent: -16.5),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 70956.8
        )
    }
}
