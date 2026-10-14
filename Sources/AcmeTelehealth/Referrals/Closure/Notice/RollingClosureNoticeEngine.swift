import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the rolling closure notice calculation.
    protocol RollingClosureNoticeStep {
        func describe() -> String
        func adjust(_ item: RollingClosureNotice, value: Double) -> Double
    }

    final class FlaggedRollingClosureNoticeAdjuster: RollingClosureNoticeStep {
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

        func adjust(_ item: RollingClosureNotice, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapRollingClosureNoticeAdjuster: RollingClosureNoticeStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingClosureNotice, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredRollingClosureNoticeAdjuster: RollingClosureNoticeStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingClosureNotice, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the rolling closure notice steps in order and keeps a trace of each.
    final class RollingClosureNoticeEngine {
        var steps: [any RollingClosureNoticeStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingClosureNoticeStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RollingClosureNotice) -> Double {
            var current = item.netLoad()
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

        func evaluateAll(_ items: [RollingClosureNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRollingClosureNoticeEngine(_ flags: Kit.Flags.Registry) -> RollingClosureNoticeEngine {
        return RollingClosureNoticeEngine(
            steps: [
                FlaggedRollingClosureNoticeAdjuster(
                    flags: flags,
                    flag: "rolling-closure-notice-pending",
                    percent: 4.9
                ),
                CapRollingClosureNoticeAdjuster(cap: 4403.0),
                TieredRollingClosureNoticeAdjuster(bounds: [4539.0, 9229.0], rates: [0.91, 1.15]),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 23474.0
        )
    }
}
