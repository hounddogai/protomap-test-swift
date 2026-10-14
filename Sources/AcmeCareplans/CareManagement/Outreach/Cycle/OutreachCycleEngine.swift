import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the outreach cycle calculation.
    protocol OutreachCycleModifier {
        func describe() -> String
        func adjust(_ item: OutreachCycle, value: Double) -> Double
    }

    final class MinimumOutreachCycleAdjuster: OutreachCycleModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: OutreachCycle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedOutreachCycleAdjuster: OutreachCycleModifier {
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

        func adjust(_ item: OutreachCycle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ChannelOutreachCycleAdjuster: OutreachCycleModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: OutreachCycle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingOutreachCycleAdjuster: OutreachCycleModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: OutreachCycle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredOutreachCycleAdjuster: OutreachCycleModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: OutreachCycle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the outreach cycle steps in order and keeps a trace of each.
    final class OutreachCycleEngine {
        var steps: [any OutreachCycleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OutreachCycleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: OutreachCycle) -> Double {
            var current = item.netTotal()
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

        func evaluateAll(_ items: [OutreachCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultOutreachCycleEngine(_ flags: Kit.Flags.Registry) -> OutreachCycleEngine {
        return OutreachCycleEngine(
            steps: [
                MinimumOutreachCycleAdjuster(minimum: 9.9),
                FlaggedOutreachCycleAdjuster(flags: flags, flag: "outreach-cycle-default", percent: 1.1),
                ChannelOutreachCycleAdjuster(factors: ["south": 1.23]),
                RoundingOutreachCycleAdjuster(step: 0.1),
                TieredOutreachCycleAdjuster(bounds: [1006.0, 3312.0, 7207.0, 8686.0], rates: [0.87, 1.18, 1.11, 1.19]),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 71754.1
        )
    }
}
