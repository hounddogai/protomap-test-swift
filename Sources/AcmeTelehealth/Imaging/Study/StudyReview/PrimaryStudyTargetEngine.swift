import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the primary study target calculation.
    protocol PrimaryStudyTargetModifier {
        func describe() -> String
        func adjust(_ item: PrimaryStudyTarget, value: Double) -> Double
    }

    final class PercentPrimaryStudyTargetAdjuster: PrimaryStudyTargetModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryStudyTarget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedPrimaryStudyTargetAdjuster: PrimaryStudyTargetModifier {
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

        func adjust(_ item: PrimaryStudyTarget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PrimaryStudyTargetAcuityOffsetAdjuster: PrimaryStudyTargetModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus acuity times \(weight)"
        }

        func adjust(_ item: PrimaryStudyTarget, value: Double) -> Double {
            return value + Double(item.acuity) * weight
        }
    }

    final class MinimumPrimaryStudyTargetAdjuster: PrimaryStudyTargetModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryStudyTarget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredPrimaryStudyTargetAdjuster: PrimaryStudyTargetModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryStudyTarget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapPrimaryStudyTargetAdjuster: PrimaryStudyTargetModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryStudyTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the primary study target steps in order and keeps a trace of each.
    final class PrimaryStudyTargetEngine {
        var steps: [any PrimaryStudyTargetModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryStudyTargetModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PrimaryStudyTarget) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimaryStudyTargetModifier = steps[index]
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

        func evaluateAll(_ items: [PrimaryStudyTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPrimaryStudyTargetEngine(_ flags: Kit.Flags.Registry) -> PrimaryStudyTargetEngine {
        return PrimaryStudyTargetEngine(
            steps: [
                PercentPrimaryStudyTargetAdjuster(percent: 8.7),
                FlaggedPrimaryStudyTargetAdjuster(flags: flags, flag: "primary-study-target-adaptive", percent: -7.5),
                PrimaryStudyTargetAcuityOffsetAdjuster(weight: 0.32),
                MinimumPrimaryStudyTargetAdjuster(minimum: 22.5),
                TieredPrimaryStudyTargetAdjuster(bounds: [2072.0, 4690.0, 5202.0], rates: [0.94, 1.14, 0.88]),
                CapPrimaryStudyTargetAdjuster(cap: 3568.0),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 8546.9
        )
    }
}
