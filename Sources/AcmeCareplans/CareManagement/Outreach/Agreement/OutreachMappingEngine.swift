import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the outreach mapping calculation.
    protocol OutreachMappingAdjuster {
        func describe() -> String
        func adjust(_ item: OutreachMapping, value: Double) -> Double
    }

    final class CapOutreachMappingAdjuster: OutreachMappingAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: OutreachMapping, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumOutreachMappingAdjuster: OutreachMappingAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: OutreachMapping, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedOutreachMappingAdjuster: OutreachMappingAdjuster {
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

        func adjust(_ item: OutreachMapping, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the outreach mapping steps in order and keeps a trace of each.
    final class OutreachMappingEngine {
        var steps: [any OutreachMappingAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OutreachMappingAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: OutreachMapping) -> Double {
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

        func evaluateAll(_ items: [OutreachMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultOutreachMappingEngine(_ flags: Kit.Flags.Registry) -> OutreachMappingEngine {
        return OutreachMappingEngine(
            steps: [
                CapOutreachMappingAdjuster(cap: 32891.0),
                MinimumOutreachMappingAdjuster(minimum: 43.7),
                FlaggedOutreachMappingAdjuster(flags: flags, flag: "outreach-mapping-pending", percent: -4.2),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 26732.7
        )
    }
}
