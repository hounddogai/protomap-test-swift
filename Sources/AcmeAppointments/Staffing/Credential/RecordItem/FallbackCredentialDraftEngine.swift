import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the fallback credential draft calculation.
    protocol FallbackCredentialDraftFactor {
        func describe() -> String
        func adjust(_ item: FallbackCredentialDraft, value: Double) -> Double
    }

    final class CapFallbackCredentialDraftAdjuster: FallbackCredentialDraftFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackCredentialDraft, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredFallbackCredentialDraftAdjuster: FallbackCredentialDraftFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackCredentialDraft, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentFallbackCredentialDraftAdjuster: FallbackCredentialDraftFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackCredentialDraft, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingFallbackCredentialDraftAdjuster: FallbackCredentialDraftFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackCredentialDraft, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedFallbackCredentialDraftAdjuster: FallbackCredentialDraftFactor {
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

        func adjust(_ item: FallbackCredentialDraft, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumFallbackCredentialDraftAdjuster: FallbackCredentialDraftFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackCredentialDraft, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the fallback credential draft steps in order and keeps a trace of each.
    final class FallbackCredentialDraftEngine {
        var steps: [any FallbackCredentialDraftFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackCredentialDraftFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FallbackCredentialDraft) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackCredentialDraftFactor = steps[index]
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

        func evaluateAll(_ items: [FallbackCredentialDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFallbackCredentialDraftEngine(_ flags: Kit.Flags.Registry) -> FallbackCredentialDraftEngine {
        return FallbackCredentialDraftEngine(
            steps: [
                CapFallbackCredentialDraftAdjuster(cap: 27605.0),
                TieredFallbackCredentialDraftAdjuster(bounds: [2007.0, 2669.0], rates: [1.06, 1.06]),
                PercentFallbackCredentialDraftAdjuster(percent: 15.1),
                RoundingFallbackCredentialDraftAdjuster(step: 0.25),
                FlaggedFallbackCredentialDraftAdjuster(
                    flags: flags,
                    flag: "fallback-credential-draft-adaptive",
                    percent: -1.7
                ),
                MinimumFallbackCredentialDraftAdjuster(minimum: 45.7),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 16037.0
        )
    }
}
