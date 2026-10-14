import AcmePlatform
import Foundation

extension Consent {
    /// One step of the strict consent form override calculation.
    protocol StrictConsentFormOverrideStep {
        func describe() -> String
        func adjust(_ item: StrictConsentFormOverride, value: Double) -> Double
    }

    final class StrictConsentFormOverrideFloorValueOffsetAdjuster: StrictConsentFormOverrideStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus floor value times \(weight)"
        }

        func adjust(_ item: StrictConsentFormOverride, value: Double) -> Double {
            return value + item.floorValue * weight
        }
    }

    final class PercentStrictConsentFormOverrideAdjuster: StrictConsentFormOverrideStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StrictConsentFormOverride, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredStrictConsentFormOverrideAdjuster: StrictConsentFormOverrideStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictConsentFormOverride, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedStrictConsentFormOverrideAdjuster: StrictConsentFormOverrideStep {
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

        func adjust(_ item: StrictConsentFormOverride, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumStrictConsentFormOverrideAdjuster: StrictConsentFormOverrideStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictConsentFormOverride, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class NameStrictConsentFormOverrideAdjuster: StrictConsentFormOverrideStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: StrictConsentFormOverride, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the strict consent form override steps in order and keeps a trace of each.
    final class StrictConsentFormOverrideEngine {
        var steps: [any StrictConsentFormOverrideStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictConsentFormOverrideStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: StrictConsentFormOverride) -> Double {
            var current = item.netTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any StrictConsentFormOverrideStep = steps[index]
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

        func evaluateAll(_ items: [StrictConsentFormOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultStrictConsentFormOverrideEngine(_ flags: Kit.Flags.Registry) -> StrictConsentFormOverrideEngine {
        return StrictConsentFormOverrideEngine(
            steps: [
                StrictConsentFormOverrideFloorValueOffsetAdjuster(weight: 1.7),
                PercentStrictConsentFormOverrideAdjuster(percent: 18.8),
                TieredStrictConsentFormOverrideAdjuster(bounds: [953.0, 7767.0], rates: [0.82, 1.12]),
                FlaggedStrictConsentFormOverrideAdjuster(
                    flags: flags,
                    flag: "strict-consent-form-override-global",
                    percent: -0.0
                ),
                MinimumStrictConsentFormOverrideAdjuster(minimum: 7.1),
                NameStrictConsentFormOverrideAdjuster(factors: ["central": 1.12, "online": 1.01, "south": 0.94]),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 12750.1
        )
    }
}
