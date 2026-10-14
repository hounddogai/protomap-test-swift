import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the care protocol assignment calculation.
    protocol CareProtocolAssignmentAdjuster {
        func describe() -> String
        func adjust(_ item: CareProtocolAssignment, value: Double) -> Double
    }

    final class CapCareProtocolAssignmentAdjuster: CareProtocolAssignmentAdjuster {
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

    final class RoundingCareProtocolAssignmentAdjuster: CareProtocolAssignmentAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CareProtocolAssignment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedCareProtocolAssignmentAdjuster: CareProtocolAssignmentAdjuster {
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

    final class CareProtocolAssignmentCeilingOffsetAdjuster: CareProtocolAssignmentAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ceiling times \(weight)"
        }

        func adjust(_ item: CareProtocolAssignment, value: Double) -> Double {
            return value + item.ceiling * weight
        }
    }

    /// Runs the care protocol assignment steps in order and keeps a trace of each.
    final class CareProtocolAssignmentEngine {
        var steps: [any CareProtocolAssignmentAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareProtocolAssignmentAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CareProtocolAssignment) -> Double {
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

        func evaluateAll(_ items: [CareProtocolAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCareProtocolAssignmentEngine(_ flags: Kit.Flags.Registry) -> CareProtocolAssignmentEngine {
        return CareProtocolAssignmentEngine(
            steps: [
                CapCareProtocolAssignmentAdjuster(cap: 3997.0),
                RoundingCareProtocolAssignmentAdjuster(step: 0.1),
                FlaggedCareProtocolAssignmentAdjuster(
                    flags: flags,
                    flag: "care-protocol-assignment-adaptive",
                    percent: -0.2
                ),
                CareProtocolAssignmentCeilingOffsetAdjuster(weight: 0.49),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 2507.4
        )
    }
}
