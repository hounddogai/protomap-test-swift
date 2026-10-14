import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the pending program notice calculation.
    protocol PendingProgramNoticeAdjuster {
        func describe() -> String
        func adjust(_ item: PendingProgramNotice, value: Double) -> Double
    }

    final class FlaggedPendingProgramNoticeAdjuster: PendingProgramNoticeAdjuster {
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

        func adjust(_ item: PendingProgramNotice, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapPendingProgramNoticeAdjuster: PendingProgramNoticeAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingProgramNotice, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredPendingProgramNoticeAdjuster: PendingProgramNoticeAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PendingProgramNotice, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumPendingProgramNoticeAdjuster: PendingProgramNoticeAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingProgramNotice, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the pending program notice steps in order and keeps a trace of each.
    final class PendingProgramNoticeEngine {
        var steps: [any PendingProgramNoticeAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingProgramNoticeAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PendingProgramNotice) -> Double {
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

        func evaluateAll(_ items: [PendingProgramNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPendingProgramNoticeEngine(_ flags: Kit.Flags.Registry) -> PendingProgramNoticeEngine {
        return PendingProgramNoticeEngine(
            steps: [
                FlaggedPendingProgramNoticeAdjuster(
                    flags: flags,
                    flag: "pending-program-notice-manual",
                    percent: -2.7
                ),
                CapPendingProgramNoticeAdjuster(cap: 10158.0),
                TieredPendingProgramNoticeAdjuster(
                    bounds: [2574.0, 4284.0, 5698.0, 9132.0],
                    rates: [1.11, 0.94, 0.86, 1.15]
                ),
                MinimumPendingProgramNoticeAdjuster(minimum: 0.0),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 84258.1
        )
    }
}
