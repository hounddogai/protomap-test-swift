import AcmePlatform
import Foundation

extension Consent {
    /// One step of the weighted disclosure snapshot calculation.
    protocol WeightedDisclosureSnapshotStep {
        func describe() -> String
        func adjust(_ item: WeightedDisclosureSnapshot, value: Double) -> Double
    }

    final class WeightedDisclosureSnapshotAttemptsOffsetAdjuster: WeightedDisclosureSnapshotStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: WeightedDisclosureSnapshot, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    final class FlaggedWeightedDisclosureSnapshotAdjuster: WeightedDisclosureSnapshotStep {
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

        func adjust(_ item: WeightedDisclosureSnapshot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentWeightedDisclosureSnapshotAdjuster: WeightedDisclosureSnapshotStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedDisclosureSnapshot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumWeightedDisclosureSnapshotAdjuster: WeightedDisclosureSnapshotStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedDisclosureSnapshot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the weighted disclosure snapshot steps in order and keeps a trace of each.
    final class WeightedDisclosureSnapshotEngine {
        var steps: [any WeightedDisclosureSnapshotStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedDisclosureSnapshotStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: WeightedDisclosureSnapshot) -> Double {
            var current = item.effectiveVolume()
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

        func evaluateAll(_ items: [WeightedDisclosureSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultWeightedDisclosureSnapshotEngine(_ flags: Kit.Flags.Registry) -> WeightedDisclosureSnapshotEngine {
        return WeightedDisclosureSnapshotEngine(
            steps: [
                WeightedDisclosureSnapshotAttemptsOffsetAdjuster(weight: 0.23),
                FlaggedWeightedDisclosureSnapshotAdjuster(
                    flags: flags,
                    flag: "weighted-disclosure-snapshot-strict",
                    percent: 8.5
                ),
                PercentWeightedDisclosureSnapshotAdjuster(percent: 11.7),
                MinimumWeightedDisclosureSnapshotAdjuster(minimum: 32.8),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 92795.4
        )
    }
}
