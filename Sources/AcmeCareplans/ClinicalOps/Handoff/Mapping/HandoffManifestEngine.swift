import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the handoff manifest calculation.
    protocol HandoffManifestFactor {
        func describe() -> String
        func adjust(_ item: HandoffManifest, value: Double) -> Double
    }

    final class FlaggedHandoffManifestAdjuster: HandoffManifestFactor {
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

        func adjust(_ item: HandoffManifest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredHandoffManifestAdjuster: HandoffManifestFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: HandoffManifest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingHandoffManifestAdjuster: HandoffManifestFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: HandoffManifest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the handoff manifest steps in order and keeps a trace of each.
    final class HandoffManifestEngine {
        var steps: [any HandoffManifestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any HandoffManifestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: HandoffManifest) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any HandoffManifestFactor = steps[index]
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

        func evaluateAll(_ items: [HandoffManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultHandoffManifestEngine(_ flags: Kit.Flags.Registry) -> HandoffManifestEngine {
        return HandoffManifestEngine(
            steps: [
                FlaggedHandoffManifestAdjuster(flags: flags, flag: "handoff-manifest-batched", percent: 8.7),
                TieredHandoffManifestAdjuster(bounds: [3321.0, 4865.0, 8030.0], rates: [1.05, 1.18, 1.0]),
                RoundingHandoffManifestAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 6864.5
        )
    }
}
