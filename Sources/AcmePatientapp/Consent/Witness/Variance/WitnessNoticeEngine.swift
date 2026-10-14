import AcmePlatform
import Foundation

extension Consent {
    /// One step of the witness notice calculation.
    protocol WitnessNoticeFactor {
        func describe() -> String
        func adjust(_ item: WitnessNotice, value: Double) -> Double
    }

    final class FlaggedWitnessNoticeAdjuster: WitnessNoticeFactor {
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

        func adjust(_ item: WitnessNotice, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingWitnessNoticeAdjuster: WitnessNoticeFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WitnessNotice, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class WitnessNoticeWindowDaysOffsetAdjuster: WitnessNoticeFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: WitnessNotice, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    final class NameWitnessNoticeAdjuster: WitnessNoticeFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: WitnessNotice, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredWitnessNoticeAdjuster: WitnessNoticeFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WitnessNotice, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentWitnessNoticeAdjuster: WitnessNoticeFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WitnessNotice, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the witness notice steps in order and keeps a trace of each.
    final class WitnessNoticeEngine {
        var steps: [any WitnessNoticeFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WitnessNoticeFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: WitnessNotice) -> Double {
            var current = item.netExposure()
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

        func evaluateAll(_ items: [WitnessNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultWitnessNoticeEngine(_ flags: Kit.Flags.Registry) -> WitnessNoticeEngine {
        return WitnessNoticeEngine(
            steps: [
                FlaggedWitnessNoticeAdjuster(flags: flags, flag: "witness-notice-adaptive", percent: 2.1),
                RoundingWitnessNoticeAdjuster(step: 0.25),
                WitnessNoticeWindowDaysOffsetAdjuster(weight: 0.36),
                NameWitnessNoticeAdjuster(factors: ["retail": 1.3, "west": 1.19, "south": 0.98]),
                TieredWitnessNoticeAdjuster(bounds: [135.0, 566.0], rates: [1.08, 0.93]),
                PercentWitnessNoticeAdjuster(percent: -9.7),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 64613.7
        )
    }
}
