import AcmePlatform
import Foundation

extension Consent {
    /// One step of the tiered consent form request calculation.
    protocol TieredConsentFormRequestAdjuster {
        func describe() -> String
        func adjust(_ item: TieredConsentFormRequest, value: Double) -> Double
    }

    final class FlaggedTieredConsentFormRequestAdjuster: TieredConsentFormRequestAdjuster {
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

        func adjust(_ item: TieredConsentFormRequest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RegionTieredConsentFormRequestAdjuster: TieredConsentFormRequestAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: TieredConsentFormRequest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredTieredConsentFormRequestAdjuster: TieredConsentFormRequestAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredConsentFormRequest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingTieredConsentFormRequestAdjuster: TieredConsentFormRequestAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredConsentFormRequest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredConsentFormRequestGraceDaysOffsetAdjuster: TieredConsentFormRequestAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: TieredConsentFormRequest, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    final class MinimumTieredConsentFormRequestAdjuster: TieredConsentFormRequestAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredConsentFormRequest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the tiered consent form request steps in order and keeps a trace of each.
    final class TieredConsentFormRequestEngine {
        var steps: [any TieredConsentFormRequestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredConsentFormRequestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: TieredConsentFormRequest) -> Double {
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

        func evaluateAll(_ items: [TieredConsentFormRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultTieredConsentFormRequestEngine(_ flags: Kit.Flags.Registry) -> TieredConsentFormRequestEngine {
        return TieredConsentFormRequestEngine(
            steps: [
                FlaggedTieredConsentFormRequestAdjuster(
                    flags: flags,
                    flag: "tiered-consent-form-request-legacy",
                    percent: -9.5
                ),
                RegionTieredConsentFormRequestAdjuster(factors: ["online": 1.13, "south": 0.89, "west": 1.28]),
                TieredTieredConsentFormRequestAdjuster(bounds: [6450.0, 6812.0], rates: [0.89, 0.87]),
                RoundingTieredConsentFormRequestAdjuster(step: 0.25),
                TieredConsentFormRequestGraceDaysOffsetAdjuster(weight: 1.66),
                MinimumTieredConsentFormRequestAdjuster(minimum: 42.2),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 29573.6
        )
    }
}
