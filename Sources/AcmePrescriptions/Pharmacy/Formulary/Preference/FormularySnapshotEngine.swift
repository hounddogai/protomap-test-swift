import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the formulary snapshot calculation.
    protocol FormularySnapshotModifier {
        func describe() -> String
        func adjust(_ item: FormularySnapshot, value: Double) -> Double
    }

    final class FlaggedFormularySnapshotAdjuster: FormularySnapshotModifier {
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

        func adjust(_ item: FormularySnapshot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumFormularySnapshotAdjuster: FormularySnapshotModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FormularySnapshot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentFormularySnapshotAdjuster: FormularySnapshotModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FormularySnapshot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the formulary snapshot steps in order and keeps a trace of each.
    final class FormularySnapshotEngine {
        var steps: [any FormularySnapshotModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FormularySnapshotModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: FormularySnapshot) -> Double {
            var current = item.weightedExposure()
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

        func evaluateAll(_ items: [FormularySnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultFormularySnapshotEngine(_ flags: Kit.Flags.Registry) -> FormularySnapshotEngine {
        return FormularySnapshotEngine(
            steps: [
                FlaggedFormularySnapshotAdjuster(flags: flags, flag: "formulary-snapshot-regional", percent: 6.3),
                MinimumFormularySnapshotAdjuster(minimum: 20.3),
                PercentFormularySnapshotAdjuster(percent: 9.3),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 96493.4
        )
    }
}
