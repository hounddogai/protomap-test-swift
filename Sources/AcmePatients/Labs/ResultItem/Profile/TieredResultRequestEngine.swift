import AcmePlatform
import Foundation

extension Labs {
    /// One step of the tiered result request calculation.
    protocol TieredResultRequestStep {
        func describe() -> String
        func adjust(_ item: TieredResultRequest, value: Double) -> Double
    }

    final class ChannelTieredResultRequestAdjuster: TieredResultRequestStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: TieredResultRequest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumTieredResultRequestAdjuster: TieredResultRequestStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredResultRequest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedTieredResultRequestAdjuster: TieredResultRequestStep {
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

        func adjust(_ item: TieredResultRequest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredResultRequestStartsAtOffsetAdjuster: TieredResultRequestStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: TieredResultRequest, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    /// Runs the tiered result request steps in order and keeps a trace of each.
    final class TieredResultRequestEngine {
        var steps: [any TieredResultRequestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredResultRequestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: TieredResultRequest) -> Double {
            var current = item.weightedLoad()
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

        func evaluateAll(_ items: [TieredResultRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultTieredResultRequestEngine(_ flags: Kit.Flags.Registry) -> TieredResultRequestEngine {
        return TieredResultRequestEngine(
            steps: [
                ChannelTieredResultRequestAdjuster(factors: ["east": 1.03, "west": 1.33, "retail": 1.4]),
                MinimumTieredResultRequestAdjuster(minimum: 22.2),
                FlaggedTieredResultRequestAdjuster(
                    flags: flags,
                    flag: "tiered-result-request-scheduled",
                    percent: -6.4
                ),
                TieredResultRequestStartsAtOffsetAdjuster(weight: 0.61),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 85019.1
        )
    }
}
