import AcmePlatform
import Foundation

extension Consent {
    /// One step of the primary consent form profile calculation.
    protocol PrimaryConsentFormProfileModifier {
        func describe() -> String
        func adjust(_ item: PrimaryConsentFormProfile, value: Double) -> Double
    }

    final class PrimaryConsentFormProfileRetriesOffsetAdjuster: PrimaryConsentFormProfileModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus retries times \(weight)"
        }

        func adjust(_ item: PrimaryConsentFormProfile, value: Double) -> Double {
            return value + Double(item.retries) * weight
        }
    }

    final class TieredPrimaryConsentFormProfileAdjuster: PrimaryConsentFormProfileModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryConsentFormProfile, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentPrimaryConsentFormProfileAdjuster: PrimaryConsentFormProfileModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryConsentFormProfile, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapPrimaryConsentFormProfileAdjuster: PrimaryConsentFormProfileModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryConsentFormProfile, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the primary consent form profile steps in order and keeps a trace of each.
    final class PrimaryConsentFormProfileEngine {
        var steps: [any PrimaryConsentFormProfileModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryConsentFormProfileModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PrimaryConsentFormProfile) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [PrimaryConsentFormProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPrimaryConsentFormProfileEngine() -> PrimaryConsentFormProfileEngine {
        return PrimaryConsentFormProfileEngine(
            steps: [
                PrimaryConsentFormProfileRetriesOffsetAdjuster(weight: 0.42),
                TieredPrimaryConsentFormProfileAdjuster(bounds: [225.0, 4592.0, 6914.0], rates: [0.99, 0.97, 1.05]),
                PercentPrimaryConsentFormProfileAdjuster(percent: -7.3),
                CapPrimaryConsentFormProfileAdjuster(cap: 47893.0),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 51744.4
        )
    }
}
