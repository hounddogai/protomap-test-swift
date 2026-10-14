import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the capped isolation schedule calculation.
    protocol CappedIsolationScheduleFactor {
        func describe() -> String
        func adjust(_ item: CappedIsolationSchedule, value: Double) -> Double
    }

    final class FlaggedCappedIsolationScheduleAdjuster: CappedIsolationScheduleFactor {
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

        func adjust(_ item: CappedIsolationSchedule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapCappedIsolationScheduleAdjuster: CappedIsolationScheduleFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedIsolationSchedule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LocaleCappedIsolationScheduleAdjuster: CappedIsolationScheduleFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: CappedIsolationSchedule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the capped isolation schedule steps in order and keeps a trace of each.
    final class CappedIsolationScheduleEngine {
        var steps: [any CappedIsolationScheduleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedIsolationScheduleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CappedIsolationSchedule) -> Double {
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

        func evaluateAll(_ items: [CappedIsolationSchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCappedIsolationScheduleEngine(_ flags: Kit.Flags.Registry) -> CappedIsolationScheduleEngine {
        return CappedIsolationScheduleEngine(
            steps: [
                FlaggedCappedIsolationScheduleAdjuster(
                    flags: flags,
                    flag: "capped-isolation-schedule-global",
                    percent: 1.2
                ),
                CapCappedIsolationScheduleAdjuster(cap: 39774.0),
                LocaleCappedIsolationScheduleAdjuster(factors: ["east": 0.92]),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 7656.9
        )
    }
}
