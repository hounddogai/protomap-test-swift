import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the census cycle calculation.
    protocol CensusCycleAdjuster {
        func describe() -> String
        func adjust(_ item: CensusCycle, value: Double) -> Double
    }

    final class FlaggedCensusCycleAdjuster: CensusCycleAdjuster {
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

        func adjust(_ item: CensusCycle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapCensusCycleAdjuster: CensusCycleAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CensusCycle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumCensusCycleAdjuster: CensusCycleAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CensusCycle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the census cycle steps in order and keeps a trace of each.
    final class CensusCycleEngine {
        var steps: [any CensusCycleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CensusCycleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CensusCycle) -> Double {
            var current = item.effectiveTotal()
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

        func evaluateAll(_ items: [CensusCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCensusCycleEngine(_ flags: Kit.Flags.Registry) -> CensusCycleEngine {
        return CensusCycleEngine(
            steps: [
                FlaggedCensusCycleAdjuster(flags: flags, flag: "census-cycle-global", percent: -3.3),
                CapCensusCycleAdjuster(cap: 37356.0),
                MinimumCensusCycleAdjuster(minimum: 16.1),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 56941.8
        )
    }
}
