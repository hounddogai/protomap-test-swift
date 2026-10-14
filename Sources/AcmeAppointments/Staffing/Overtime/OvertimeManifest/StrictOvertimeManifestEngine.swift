import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the strict overtime manifest calculation.
    protocol StrictOvertimeManifestStep {
        func describe() -> String
        func adjust(_ item: StrictOvertimeManifest, value: Double) -> Double
    }

    final class NameStrictOvertimeManifestAdjuster: StrictOvertimeManifestStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: StrictOvertimeManifest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class StrictOvertimeManifestScoreOffsetAdjuster: StrictOvertimeManifestStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: StrictOvertimeManifest, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class PercentStrictOvertimeManifestAdjuster: StrictOvertimeManifestStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StrictOvertimeManifest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedStrictOvertimeManifestAdjuster: StrictOvertimeManifestStep {
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

        func adjust(_ item: StrictOvertimeManifest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the strict overtime manifest steps in order and keeps a trace of each.
    final class StrictOvertimeManifestEngine {
        var steps: [any StrictOvertimeManifestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictOvertimeManifestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: StrictOvertimeManifest) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any StrictOvertimeManifestStep = steps[index]
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

        func evaluateAll(_ items: [StrictOvertimeManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultStrictOvertimeManifestEngine(_ flags: Kit.Flags.Registry) -> StrictOvertimeManifestEngine {
        return StrictOvertimeManifestEngine(
            steps: [
                NameStrictOvertimeManifestAdjuster(factors: ["central": 1.1]),
                StrictOvertimeManifestScoreOffsetAdjuster(weight: 0.2),
                PercentStrictOvertimeManifestAdjuster(percent: 8.7),
                FlaggedStrictOvertimeManifestAdjuster(
                    flags: flags,
                    flag: "strict-overtime-manifest-global",
                    percent: -8.0
                ),
            ],
            trace: [],
            floor: 0.0,
            ceiling: 70371.0
        )
    }
}
