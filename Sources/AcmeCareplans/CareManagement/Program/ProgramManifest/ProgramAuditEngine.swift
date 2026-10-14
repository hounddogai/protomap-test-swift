import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the program audit calculation.
    protocol ProgramAuditFactor {
        func describe() -> String
        func adjust(_ item: ProgramAudit, value: Double) -> Double
    }

    final class TieredProgramAuditAdjuster: ProgramAuditFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ProgramAudit, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapProgramAuditAdjuster: ProgramAuditFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ProgramAudit, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedProgramAuditAdjuster: ProgramAuditFactor {
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

        func adjust(_ item: ProgramAudit, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingProgramAuditAdjuster: ProgramAuditFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ProgramAudit, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the program audit steps in order and keeps a trace of each.
    final class ProgramAuditEngine {
        var steps: [any ProgramAuditFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ProgramAuditFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ProgramAudit) -> Double {
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

        func evaluateAll(_ items: [ProgramAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultProgramAuditEngine(_ flags: Kit.Flags.Registry) -> ProgramAuditEngine {
        return ProgramAuditEngine(
            steps: [
                TieredProgramAuditAdjuster(bounds: [2504.0, 7408.0], rates: [0.93, 0.96]),
                CapProgramAuditAdjuster(cap: 31644.0),
                FlaggedProgramAuditAdjuster(flags: flags, flag: "program-audit-rolling", percent: 3.1),
                RoundingProgramAuditAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 90893.0
        )
    }
}
