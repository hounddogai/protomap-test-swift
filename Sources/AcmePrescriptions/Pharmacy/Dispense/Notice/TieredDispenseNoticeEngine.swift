import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the tiered dispense notice calculation.
    protocol TieredDispenseNoticeModifier {
        func describe() -> String
        func adjust(_ item: TieredDispenseNotice, value: Double) -> Double
    }

    final class FlaggedTieredDispenseNoticeAdjuster: TieredDispenseNoticeModifier {
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

        func adjust(_ item: TieredDispenseNotice, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingTieredDispenseNoticeAdjuster: TieredDispenseNoticeModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredDispenseNotice, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredDispenseNoticeExpiresAtOffsetAdjuster: TieredDispenseNoticeModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: TieredDispenseNotice, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    final class TieredTieredDispenseNoticeAdjuster: TieredDispenseNoticeModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredDispenseNotice, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the tiered dispense notice steps in order and keeps a trace of each.
    final class TieredDispenseNoticeEngine {
        var steps: [any TieredDispenseNoticeModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredDispenseNoticeModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: TieredDispenseNotice) -> Double {
            var current = item.adjustedTotal()
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

        func evaluateAll(_ items: [TieredDispenseNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultTieredDispenseNoticeEngine(_ flags: Kit.Flags.Registry) -> TieredDispenseNoticeEngine {
        return TieredDispenseNoticeEngine(
            steps: [
                FlaggedTieredDispenseNoticeAdjuster(
                    flags: flags,
                    flag: "tiered-dispense-notice-fallback",
                    percent: -0.0
                ),
                RoundingTieredDispenseNoticeAdjuster(step: 0.25),
                TieredDispenseNoticeExpiresAtOffsetAdjuster(weight: 0.65),
                TieredTieredDispenseNoticeAdjuster(bounds: [2352.0, 5688.0, 7967.0], rates: [1.11, 0.91, 1.13]),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 94010.1
        )
    }
}
