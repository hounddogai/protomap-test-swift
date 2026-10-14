import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the primary care protocol score calculation.
    protocol PrimaryCareProtocolScoreModifier {
        func describe() -> String
        func adjust(_ item: PrimaryCareProtocolScore, value: Double) -> Double
    }

    final class CapPrimaryCareProtocolScoreAdjuster: PrimaryCareProtocolScoreModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryCareProtocolScore, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedPrimaryCareProtocolScoreAdjuster: PrimaryCareProtocolScoreModifier {
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

        func adjust(_ item: PrimaryCareProtocolScore, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumPrimaryCareProtocolScoreAdjuster: PrimaryCareProtocolScoreModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryCareProtocolScore, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentPrimaryCareProtocolScoreAdjuster: PrimaryCareProtocolScoreModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryCareProtocolScore, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the primary care protocol score steps in order and keeps a trace of each.
    final class PrimaryCareProtocolScoreEngine {
        var steps: [any PrimaryCareProtocolScoreModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryCareProtocolScoreModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PrimaryCareProtocolScore) -> Double {
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

        func evaluateAll(_ items: [PrimaryCareProtocolScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPrimaryCareProtocolScoreEngine(_ flags: Kit.Flags.Registry) -> PrimaryCareProtocolScoreEngine {
        return PrimaryCareProtocolScoreEngine(
            steps: [
                CapPrimaryCareProtocolScoreAdjuster(cap: 33073.0),
                FlaggedPrimaryCareProtocolScoreAdjuster(
                    flags: flags,
                    flag: "primary-care-protocol-score-adaptive",
                    percent: 8.3
                ),
                MinimumPrimaryCareProtocolScoreAdjuster(minimum: 29.1),
                PercentPrimaryCareProtocolScoreAdjuster(percent: -15.3),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 6146.0
        )
    }
}
