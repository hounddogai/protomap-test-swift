import AcmePlatform
import Foundation

extension Consent {
    /// One step of the consent form checkpoint calculation.
    protocol ConsentFormCheckpointModifier {
        func describe() -> String
        func adjust(_ item: ConsentFormCheckpoint, value: Double) -> Double
    }

    final class CapConsentFormCheckpointAdjuster: ConsentFormCheckpointModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ConsentFormCheckpoint, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredConsentFormCheckpointAdjuster: ConsentFormCheckpointModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ConsentFormCheckpoint, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedConsentFormCheckpointAdjuster: ConsentFormCheckpointModifier {
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

        func adjust(_ item: ConsentFormCheckpoint, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the consent form checkpoint steps in order and keeps a trace of each.
    final class ConsentFormCheckpointEngine {
        var steps: [any ConsentFormCheckpointModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ConsentFormCheckpointModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ConsentFormCheckpoint) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ConsentFormCheckpointModifier = steps[index]
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

        func evaluateAll(_ items: [ConsentFormCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultConsentFormCheckpointEngine(_ flags: Kit.Flags.Registry) -> ConsentFormCheckpointEngine {
        return ConsentFormCheckpointEngine(
            steps: [
                CapConsentFormCheckpointAdjuster(cap: 1961.0),
                TieredConsentFormCheckpointAdjuster(
                    bounds: [1044.0, 5723.0, 5864.0, 6507.0],
                    rates: [0.9, 1.02, 0.81, 0.82]
                ),
                FlaggedConsentFormCheckpointAdjuster(
                    flags: flags,
                    flag: "consent-form-checkpoint-fallback",
                    percent: 9.1
                ),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 86204.1
        )
    }
}
