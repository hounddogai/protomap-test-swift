import AcmePlatform
import Foundation

extension Consent {
    /// One step of the adaptive revocation exception calculation.
    protocol AdaptiveRevocationExceptionAdjuster {
        func describe() -> String
        func adjust(_ item: AdaptiveRevocationException, value: Double) -> Double
    }

    final class PercentAdaptiveRevocationExceptionAdjuster: AdaptiveRevocationExceptionAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveRevocationException, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedAdaptiveRevocationExceptionAdjuster: AdaptiveRevocationExceptionAdjuster {
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

        func adjust(_ item: AdaptiveRevocationException, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapAdaptiveRevocationExceptionAdjuster: AdaptiveRevocationExceptionAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveRevocationException, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class AdaptiveRevocationExceptionMarginOffsetAdjuster: AdaptiveRevocationExceptionAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus margin times \(weight)"
        }

        func adjust(_ item: AdaptiveRevocationException, value: Double) -> Double {
            return value + item.margin * weight
        }
    }

    /// Runs the adaptive revocation exception steps in order and keeps a trace of each.
    final class AdaptiveRevocationExceptionEngine {
        var steps: [any AdaptiveRevocationExceptionAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveRevocationExceptionAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AdaptiveRevocationException) -> Double {
            var current = item.effectiveLoad()
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

        func evaluateAll(_ items: [AdaptiveRevocationException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAdaptiveRevocationExceptionEngine(_ flags: Kit.Flags.Registry) -> AdaptiveRevocationExceptionEngine {
        return AdaptiveRevocationExceptionEngine(
            steps: [
                PercentAdaptiveRevocationExceptionAdjuster(percent: 3.8),
                FlaggedAdaptiveRevocationExceptionAdjuster(
                    flags: flags,
                    flag: "adaptive-revocation-exception-primary",
                    percent: 9.0
                ),
                CapAdaptiveRevocationExceptionAdjuster(cap: 15161.0),
                AdaptiveRevocationExceptionMarginOffsetAdjuster(weight: 0.77),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 38640.7
        )
    }
}
