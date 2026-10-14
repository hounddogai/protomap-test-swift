import AcmePlatform
import Foundation

extension Labs {
    /// One step of the manual specimen segment calculation.
    protocol ManualSpecimenSegmentStep {
        func describe() -> String
        func adjust(_ item: ManualSpecimenSegment, value: Double) -> Double
    }

    final class MinimumManualSpecimenSegmentAdjuster: ManualSpecimenSegmentStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualSpecimenSegment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredManualSpecimenSegmentAdjuster: ManualSpecimenSegmentStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualSpecimenSegment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedManualSpecimenSegmentAdjuster: ManualSpecimenSegmentStep {
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

        func adjust(_ item: ManualSpecimenSegment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ManualSpecimenSegmentExpiresAtOffsetAdjuster: ManualSpecimenSegmentStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: ManualSpecimenSegment, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    /// Runs the manual specimen segment steps in order and keeps a trace of each.
    final class ManualSpecimenSegmentEngine {
        var steps: [any ManualSpecimenSegmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualSpecimenSegmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ManualSpecimenSegment) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualSpecimenSegmentStep = steps[index]
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

        func evaluateAll(_ items: [ManualSpecimenSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultManualSpecimenSegmentEngine(_ flags: Kit.Flags.Registry) -> ManualSpecimenSegmentEngine {
        return ManualSpecimenSegmentEngine(
            steps: [
                MinimumManualSpecimenSegmentAdjuster(minimum: 7.9),
                TieredManualSpecimenSegmentAdjuster(bounds: [5414.0, 7842.0], rates: [1.2, 0.99]),
                FlaggedManualSpecimenSegmentAdjuster(
                    flags: flags,
                    flag: "manual-specimen-segment-pending",
                    percent: 9.4
                ),
                ManualSpecimenSegmentExpiresAtOffsetAdjuster(weight: 1.91),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 65457.5
        )
    }
}
