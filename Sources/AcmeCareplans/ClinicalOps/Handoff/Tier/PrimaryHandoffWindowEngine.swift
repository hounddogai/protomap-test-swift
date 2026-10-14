import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the primary handoff window calculation.
    protocol PrimaryHandoffWindowAdjuster {
        func describe() -> String
        func adjust(_ item: PrimaryHandoffWindow, value: Double) -> Double
    }

    final class FlaggedPrimaryHandoffWindowAdjuster: PrimaryHandoffWindowAdjuster {
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

        func adjust(_ item: PrimaryHandoffWindow, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumPrimaryHandoffWindowAdjuster: PrimaryHandoffWindowAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryHandoffWindow, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapPrimaryHandoffWindowAdjuster: PrimaryHandoffWindowAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryHandoffWindow, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingPrimaryHandoffWindowAdjuster: PrimaryHandoffWindowAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryHandoffWindow, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the primary handoff window steps in order and keeps a trace of each.
    final class PrimaryHandoffWindowEngine {
        var steps: [any PrimaryHandoffWindowAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryHandoffWindowAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PrimaryHandoffWindow) -> Double {
            var current = item.adjustedValue()
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

        func evaluateAll(_ items: [PrimaryHandoffWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPrimaryHandoffWindowEngine(_ flags: Kit.Flags.Registry) -> PrimaryHandoffWindowEngine {
        return PrimaryHandoffWindowEngine(
            steps: [
                FlaggedPrimaryHandoffWindowAdjuster(
                    flags: flags,
                    flag: "primary-handoff-window-weighted",
                    percent: -7.1
                ),
                MinimumPrimaryHandoffWindowAdjuster(minimum: 47.7),
                CapPrimaryHandoffWindowAdjuster(cap: 48598.0),
                RoundingPrimaryHandoffWindowAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 47306.5
        )
    }
}
