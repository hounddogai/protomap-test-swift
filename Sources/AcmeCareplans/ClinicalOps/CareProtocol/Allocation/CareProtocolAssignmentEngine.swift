import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the care protocol assignment calculation.
    protocol CareProtocolAssignmentModifier {
        func describe() -> String
        func adjust(_ item: CareProtocolAssignment, value: Double) -> Double
    }

    final class FlaggedCareProtocolAssignmentAdjuster: CareProtocolAssignmentModifier {
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

        func adjust(_ item: CareProtocolAssignment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RegionCareProtocolAssignmentAdjuster: CareProtocolAssignmentModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: CareProtocolAssignment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumCareProtocolAssignmentAdjuster: CareProtocolAssignmentModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CareProtocolAssignment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapCareProtocolAssignmentAdjuster: CareProtocolAssignmentModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CareProtocolAssignment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the care protocol assignment steps in order and keeps a trace of each.
    final class CareProtocolAssignmentEngine {
        var steps: [any CareProtocolAssignmentModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareProtocolAssignmentModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CareProtocolAssignment) -> Double {
            var current = item.effectiveLoad()
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

        func evaluateAll(_ items: [CareProtocolAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCareProtocolAssignmentEngine(_ flags: Kit.Flags.Registry) -> CareProtocolAssignmentEngine {
        return CareProtocolAssignmentEngine(
            steps: [
                FlaggedCareProtocolAssignmentAdjuster(
                    flags: flags,
                    flag: "care-protocol-assignment-weighted",
                    percent: 6.1
                ),
                RegionCareProtocolAssignmentAdjuster(factors: ["east": 0.78]),
                MinimumCareProtocolAssignmentAdjuster(minimum: 31.6),
                CapCareProtocolAssignmentAdjuster(cap: 11600.0),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 23727.4
        )
    }
}
