import AcmePlatform
import Foundation

extension Labs {
    /// One step of the reference range window calculation.
    protocol ReferenceRangeWindowModifier {
        func describe() -> String
        func adjust(_ item: ReferenceRangeWindow, value: Double) -> Double
    }

    final class RoundingReferenceRangeWindowAdjuster: ReferenceRangeWindowModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ReferenceRangeWindow, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedReferenceRangeWindowAdjuster: ReferenceRangeWindowModifier {
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

        func adjust(_ item: ReferenceRangeWindow, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ReferenceRangeWindowWindowDaysOffsetAdjuster: ReferenceRangeWindowModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: ReferenceRangeWindow, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    /// Runs the reference range window steps in order and keeps a trace of each.
    final class ReferenceRangeWindowEngine {
        var steps: [any ReferenceRangeWindowModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReferenceRangeWindowModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ReferenceRangeWindow) -> Double {
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

        func evaluateAll(_ items: [ReferenceRangeWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultReferenceRangeWindowEngine(_ flags: Kit.Flags.Registry) -> ReferenceRangeWindowEngine {
        return ReferenceRangeWindowEngine(
            steps: [
                RoundingReferenceRangeWindowAdjuster(step: 0.5),
                FlaggedReferenceRangeWindowAdjuster(
                    flags: flags,
                    flag: "reference-range-window-batched",
                    percent: -7.7
                ),
                ReferenceRangeWindowWindowDaysOffsetAdjuster(weight: 1.28),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 39985.7
        )
    }
}
