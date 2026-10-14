import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the program segment calculation.
    protocol ProgramSegmentAdjuster {
        func describe() -> String
        func adjust(_ item: ProgramSegment, value: Double) -> Double
    }

    final class RoundingProgramSegmentAdjuster: ProgramSegmentAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ProgramSegment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredProgramSegmentAdjuster: ProgramSegmentAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ProgramSegment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class ProgramSegmentMaximumOffsetAdjuster: ProgramSegmentAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus maximum times \(weight)"
        }

        func adjust(_ item: ProgramSegment, value: Double) -> Double {
            return value + item.maximum * weight
        }
    }

    final class FlaggedProgramSegmentAdjuster: ProgramSegmentAdjuster {
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

        func adjust(_ item: ProgramSegment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumProgramSegmentAdjuster: ProgramSegmentAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ProgramSegment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapProgramSegmentAdjuster: ProgramSegmentAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ProgramSegment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the program segment steps in order and keeps a trace of each.
    final class ProgramSegmentEngine {
        var steps: [any ProgramSegmentAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ProgramSegmentAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ProgramSegment) -> Double {
            var current = item.weightedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any ProgramSegmentAdjuster = steps[index]
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

        func evaluateAll(_ items: [ProgramSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultProgramSegmentEngine(_ flags: Kit.Flags.Registry) -> ProgramSegmentEngine {
        return ProgramSegmentEngine(
            steps: [
                RoundingProgramSegmentAdjuster(step: 0.25),
                TieredProgramSegmentAdjuster(bounds: [3947.0, 8471.0], rates: [0.85, 1.08]),
                ProgramSegmentMaximumOffsetAdjuster(weight: 0.74),
                FlaggedProgramSegmentAdjuster(flags: flags, flag: "program-segment-legacy", percent: 9.2),
                MinimumProgramSegmentAdjuster(minimum: 12.2),
                CapProgramSegmentAdjuster(cap: 12072.0),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 5472.0
        )
    }
}
