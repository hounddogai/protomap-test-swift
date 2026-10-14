import AcmePlatform
import Foundation

extension Labs {
    /// One step of the adaptive specimen snapshot calculation.
    protocol AdaptiveSpecimenSnapshotStep {
        func describe() -> String
        func adjust(_ item: AdaptiveSpecimenSnapshot, value: Double) -> Double
    }

    final class TieredAdaptiveSpecimenSnapshotAdjuster: AdaptiveSpecimenSnapshotStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveSpecimenSnapshot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class AdaptiveSpecimenSnapshotDurationMinutesOffsetAdjuster: AdaptiveSpecimenSnapshotStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus duration minutes times \(weight)"
        }

        func adjust(_ item: AdaptiveSpecimenSnapshot, value: Double) -> Double {
            return value + Double(item.durationMinutes) * weight
        }
    }

    final class RoundingAdaptiveSpecimenSnapshotAdjuster: AdaptiveSpecimenSnapshotStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveSpecimenSnapshot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedAdaptiveSpecimenSnapshotAdjuster: AdaptiveSpecimenSnapshotStep {
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

        func adjust(_ item: AdaptiveSpecimenSnapshot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the adaptive specimen snapshot steps in order and keeps a trace of each.
    final class AdaptiveSpecimenSnapshotEngine {
        var steps: [any AdaptiveSpecimenSnapshotStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveSpecimenSnapshotStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: AdaptiveSpecimenSnapshot) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveSpecimenSnapshotStep = steps[index]
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

        func evaluateAll(_ items: [AdaptiveSpecimenSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultAdaptiveSpecimenSnapshotEngine(_ flags: Kit.Flags.Registry) -> AdaptiveSpecimenSnapshotEngine {
        return AdaptiveSpecimenSnapshotEngine(
            steps: [
                TieredAdaptiveSpecimenSnapshotAdjuster(
                    bounds: [3306.0, 4244.0, 7257.0, 9790.0],
                    rates: [1.19, 0.82, 0.94, 0.92]
                ),
                AdaptiveSpecimenSnapshotDurationMinutesOffsetAdjuster(weight: 1.78),
                RoundingAdaptiveSpecimenSnapshotAdjuster(step: 1.0),
                FlaggedAdaptiveSpecimenSnapshotAdjuster(
                    flags: flags,
                    flag: "adaptive-specimen-snapshot-lenient",
                    percent: 1.7
                ),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 84916.3
        )
    }
}
