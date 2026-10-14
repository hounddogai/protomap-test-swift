import AcmePlatform
import Foundation

extension Consent {
    /// One step of the strict proxy baseline calculation.
    protocol StrictProxyBaselineStep {
        func describe() -> String
        func adjust(_ item: StrictProxyBaseline, value: Double) -> Double
    }

    final class TitleStrictProxyBaselineAdjuster: StrictProxyBaselineStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: StrictProxyBaseline, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedStrictProxyBaselineAdjuster: StrictProxyBaselineStep {
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

        func adjust(_ item: StrictProxyBaseline, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingStrictProxyBaselineAdjuster: StrictProxyBaselineStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictProxyBaseline, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class StrictProxyBaselineGraceDaysOffsetAdjuster: StrictProxyBaselineStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: StrictProxyBaseline, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    final class CapStrictProxyBaselineAdjuster: StrictProxyBaselineStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StrictProxyBaseline, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the strict proxy baseline steps in order and keeps a trace of each.
    final class StrictProxyBaselineEngine {
        var steps: [any StrictProxyBaselineStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictProxyBaselineStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: StrictProxyBaseline) -> Double {
            var current = item.netVolume()
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

        func evaluateAll(_ items: [StrictProxyBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultStrictProxyBaselineEngine(_ flags: Kit.Flags.Registry) -> StrictProxyBaselineEngine {
        return StrictProxyBaselineEngine(
            steps: [
                TitleStrictProxyBaselineAdjuster(factors: ["central": 0.73, "south": 0.94]),
                FlaggedStrictProxyBaselineAdjuster(flags: flags, flag: "strict-proxy-baseline-regional", percent: 0.4),
                RoundingStrictProxyBaselineAdjuster(step: 1.0),
                StrictProxyBaselineGraceDaysOffsetAdjuster(weight: 1.92),
                CapStrictProxyBaselineAdjuster(cap: 37133.0),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 90554.4
        )
    }
}
