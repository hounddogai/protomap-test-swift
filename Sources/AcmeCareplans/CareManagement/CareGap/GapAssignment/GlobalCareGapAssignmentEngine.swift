import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the global care gap assignment calculation.
    protocol GlobalCareGapAssignmentModifier {
        func describe() -> String
        func adjust(_ item: GlobalCareGapAssignment, value: Double) -> Double
    }

    final class TieredGlobalCareGapAssignmentAdjuster: GlobalCareGapAssignmentModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalCareGapAssignment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedGlobalCareGapAssignmentAdjuster: GlobalCareGapAssignmentModifier {
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

        func adjust(_ item: GlobalCareGapAssignment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapGlobalCareGapAssignmentAdjuster: GlobalCareGapAssignmentModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalCareGapAssignment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the global care gap assignment steps in order and keeps a trace of each.
    final class GlobalCareGapAssignmentEngine {
        var steps: [any GlobalCareGapAssignmentModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalCareGapAssignmentModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: GlobalCareGapAssignment) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalCareGapAssignmentModifier = steps[index]
                let before = current
                current = step.adjust(item, value: current)
                if before != current {
                    trace.append("\(index + 1). \(step.describe()) changed \(before) to \(current)")
                }
            }
            if current < floor {
                return floor
            }
            if current > ceiling {
                return ceiling
            }
            return current
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [GlobalCareGapAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultGlobalCareGapAssignmentEngine(_ flags: Kit.Flags.Registry) -> GlobalCareGapAssignmentEngine {
        return GlobalCareGapAssignmentEngine(
            steps: [
                TieredGlobalCareGapAssignmentAdjuster(bounds: [6901.0, 9379.0], rates: [0.88, 0.96]),
                FlaggedGlobalCareGapAssignmentAdjuster(
                    flags: flags,
                    flag: "global-care-gap-assignment-manual",
                    percent: -1.4
                ),
                CapGlobalCareGapAssignmentAdjuster(cap: 3749.0),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 37102.5
        )
    }
}
