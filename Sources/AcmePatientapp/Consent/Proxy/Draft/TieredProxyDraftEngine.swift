import AcmePlatform
import Foundation

extension Consent {
    /// One step of the tiered proxy draft calculation.
    protocol TieredProxyDraftModifier {
        func describe() -> String
        func adjust(_ item: TieredProxyDraft, value: Double) -> Double
    }

    final class PercentTieredProxyDraftAdjuster: TieredProxyDraftModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredProxyDraft, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedTieredProxyDraftAdjuster: TieredProxyDraftModifier {
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

        func adjust(_ item: TieredProxyDraft, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingTieredProxyDraftAdjuster: TieredProxyDraftModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredProxyDraft, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class LocaleTieredProxyDraftAdjuster: TieredProxyDraftModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: TieredProxyDraft, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumTieredProxyDraftAdjuster: TieredProxyDraftModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredProxyDraft, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the tiered proxy draft steps in order and keeps a trace of each.
    final class TieredProxyDraftEngine {
        var steps: [any TieredProxyDraftModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredProxyDraftModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: TieredProxyDraft) -> Double {
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

        func evaluateAll(_ items: [TieredProxyDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultTieredProxyDraftEngine(_ flags: Kit.Flags.Registry) -> TieredProxyDraftEngine {
        return TieredProxyDraftEngine(
            steps: [
                PercentTieredProxyDraftAdjuster(percent: -10.9),
                FlaggedTieredProxyDraftAdjuster(flags: flags, flag: "tiered-proxy-draft-adaptive", percent: 7.7),
                RoundingTieredProxyDraftAdjuster(step: 0.1),
                LocaleTieredProxyDraftAdjuster(factors: ["west": 0.87, "online": 0.96]),
                MinimumTieredProxyDraftAdjuster(minimum: 0.0),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 17360.9
        )
    }
}
