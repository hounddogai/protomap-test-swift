import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the handoff notice calculation.
    protocol HandoffNoticeAdjuster {
        func describe() -> String
        func adjust(_ item: HandoffNotice, value: Double) -> Double
    }

    final class CapHandoffNoticeAdjuster: HandoffNoticeAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: HandoffNotice, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedHandoffNoticeAdjuster: HandoffNoticeAdjuster {
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

        func adjust(_ item: HandoffNotice, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredHandoffNoticeAdjuster: HandoffNoticeAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: HandoffNotice, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingHandoffNoticeAdjuster: HandoffNoticeAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: HandoffNotice, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the handoff notice steps in order and keeps a trace of each.
    final class HandoffNoticeEngine {
        var steps: [any HandoffNoticeAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any HandoffNoticeAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: HandoffNotice) -> Double {
            var current = item.netValue()
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

        func evaluateAll(_ items: [HandoffNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultHandoffNoticeEngine(_ flags: Kit.Flags.Registry) -> HandoffNoticeEngine {
        return HandoffNoticeEngine(
            steps: [
                CapHandoffNoticeAdjuster(cap: 30791.0),
                FlaggedHandoffNoticeAdjuster(flags: flags, flag: "handoff-notice-adaptive", percent: -4.5),
                TieredHandoffNoticeAdjuster(bounds: [1085.0, 2326.0, 5492.0, 9895.0], rates: [1.06, 1.14, 0.95, 1.15]),
                RoundingHandoffNoticeAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 7573.1
        )
    }
}
