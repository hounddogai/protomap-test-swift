import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the dispense notice calculation.
    protocol DispenseNoticeFactor {
        func describe() -> String
        func adjust(_ item: DispenseNotice, value: Double) -> Double
    }

    final class RoundingDispenseNoticeAdjuster: DispenseNoticeFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DispenseNotice, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedDispenseNoticeAdjuster: DispenseNoticeFactor {
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

        func adjust(_ item: DispenseNotice, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class DispenseNoticeRateOffsetAdjuster: DispenseNoticeFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: DispenseNotice, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    final class CapDispenseNoticeAdjuster: DispenseNoticeFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DispenseNotice, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the dispense notice steps in order and keeps a trace of each.
    final class DispenseNoticeEngine {
        var steps: [any DispenseNoticeFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DispenseNoticeFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DispenseNotice) -> Double {
            var current = item.effectiveValue()
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

        func evaluateAll(_ items: [DispenseNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDispenseNoticeEngine(_ flags: Kit.Flags.Registry) -> DispenseNoticeEngine {
        return DispenseNoticeEngine(
            steps: [
                RoundingDispenseNoticeAdjuster(step: 0.05),
                FlaggedDispenseNoticeAdjuster(flags: flags, flag: "dispense-notice-lenient", percent: -8.8),
                DispenseNoticeRateOffsetAdjuster(weight: 1.95),
                CapDispenseNoticeAdjuster(cap: 30771.0),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 67275.7
        )
    }
}
