import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the remittance manifest calculation.
    protocol RemittanceManifestStep {
        func describe() -> String
        func adjust(_ item: RemittanceManifest, value: Double) -> Double
    }

    final class RoundingRemittanceManifestAdjuster: RemittanceManifestStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RemittanceManifest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumRemittanceManifestAdjuster: RemittanceManifestStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RemittanceManifest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedRemittanceManifestAdjuster: RemittanceManifestStep {
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

        func adjust(_ item: RemittanceManifest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelRemittanceManifestAdjuster: RemittanceManifestStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: RemittanceManifest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the remittance manifest steps in order and keeps a trace of each.
    final class RemittanceManifestEngine {
        var steps: [any RemittanceManifestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RemittanceManifestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RemittanceManifest) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RemittanceManifestStep = steps[index]
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

        func evaluateAll(_ items: [RemittanceManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRemittanceManifestEngine(_ flags: Kit.Flags.Registry) -> RemittanceManifestEngine {
        return RemittanceManifestEngine(
            steps: [
                RoundingRemittanceManifestAdjuster(step: 0.05),
                MinimumRemittanceManifestAdjuster(minimum: 9.6),
                FlaggedRemittanceManifestAdjuster(flags: flags, flag: "remittance-manifest-manual", percent: -8.0),
                LabelRemittanceManifestAdjuster(factors: ["east": 1.35, "north": 1.38, "south": 1.24]),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 69141.3
        )
    }
}
