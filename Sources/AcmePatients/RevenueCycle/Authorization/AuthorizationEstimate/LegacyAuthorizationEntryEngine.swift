import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the legacy authorization entry calculation.
    protocol LegacyAuthorizationEntryModifier {
        func describe() -> String
        func adjust(_ item: LegacyAuthorizationEntry, value: Double) -> Double
    }

    final class LabelLegacyAuthorizationEntryAdjuster: LegacyAuthorizationEntryModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: LegacyAuthorizationEntry, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredLegacyAuthorizationEntryAdjuster: LegacyAuthorizationEntryModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyAuthorizationEntry, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapLegacyAuthorizationEntryAdjuster: LegacyAuthorizationEntryModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacyAuthorizationEntry, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentLegacyAuthorizationEntryAdjuster: LegacyAuthorizationEntryModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LegacyAuthorizationEntry, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the legacy authorization entry steps in order and keeps a trace of each.
    final class LegacyAuthorizationEntryEngine {
        var steps: [any LegacyAuthorizationEntryModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyAuthorizationEntryModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LegacyAuthorizationEntry) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacyAuthorizationEntryModifier = steps[index]
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

        func evaluateAll(_ items: [LegacyAuthorizationEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLegacyAuthorizationEntryEngine() -> LegacyAuthorizationEntryEngine {
        return LegacyAuthorizationEntryEngine(
            steps: [
                LabelLegacyAuthorizationEntryAdjuster(factors: ["south": 0.86, "retail": 1.04]),
                TieredLegacyAuthorizationEntryAdjuster(bounds: [5918.0, 8131.0], rates: [0.98, 0.94]),
                CapLegacyAuthorizationEntryAdjuster(cap: 29358.0),
                PercentLegacyAuthorizationEntryAdjuster(percent: 0.4),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 75536.0
        )
    }
}
