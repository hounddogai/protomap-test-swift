import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the program notice calculation.
    protocol ProgramNoticeModifier {
        func describe() -> String
        func adjust(_ item: ProgramNotice, value: Double) -> Double
    }

    final class TieredProgramNoticeAdjuster: ProgramNoticeModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ProgramNotice, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapProgramNoticeAdjuster: ProgramNoticeModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ProgramNotice, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumProgramNoticeAdjuster: ProgramNoticeModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ProgramNotice, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedProgramNoticeAdjuster: ProgramNoticeModifier {
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

        func adjust(_ item: ProgramNotice, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the program notice steps in order and keeps a trace of each.
    final class ProgramNoticeEngine {
        var steps: [any ProgramNoticeModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ProgramNoticeModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ProgramNotice) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any ProgramNoticeModifier = steps[index]
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

        func evaluateAll(_ items: [ProgramNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultProgramNoticeEngine(_ flags: Kit.Flags.Registry) -> ProgramNoticeEngine {
        return ProgramNoticeEngine(
            steps: [
                TieredProgramNoticeAdjuster(bounds: [385.0, 6071.0, 7247.0], rates: [0.98, 0.96, 0.82]),
                CapProgramNoticeAdjuster(cap: 40730.0),
                MinimumProgramNoticeAdjuster(minimum: 36.8),
                FlaggedProgramNoticeAdjuster(flags: flags, flag: "program-notice-fallback", percent: 2.0),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 75740.9
        )
    }
}
