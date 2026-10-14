import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the regional credential draft calculation.
    protocol RegionalCredentialDraftStep {
        func describe() -> String
        func adjust(_ item: RegionalCredentialDraft, value: Double) -> Double
    }

    final class FlaggedRegionalCredentialDraftAdjuster: RegionalCredentialDraftStep {
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

        func adjust(_ item: RegionalCredentialDraft, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingRegionalCredentialDraftAdjuster: RegionalCredentialDraftStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalCredentialDraft, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapRegionalCredentialDraftAdjuster: RegionalCredentialDraftStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalCredentialDraft, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredRegionalCredentialDraftAdjuster: RegionalCredentialDraftStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalCredentialDraft, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class SourceRegionalCredentialDraftAdjuster: RegionalCredentialDraftStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: RegionalCredentialDraft, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RegionalCredentialDraftCapacityOffsetAdjuster: RegionalCredentialDraftStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: RegionalCredentialDraft, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    /// Runs the regional credential draft steps in order and keeps a trace of each.
    final class RegionalCredentialDraftEngine {
        var steps: [any RegionalCredentialDraftStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalCredentialDraftStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RegionalCredentialDraft) -> Double {
            var current = item.adjustedLoad()
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

        func evaluateAll(_ items: [RegionalCredentialDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRegionalCredentialDraftEngine(_ flags: Kit.Flags.Registry) -> RegionalCredentialDraftEngine {
        return RegionalCredentialDraftEngine(
            steps: [
                FlaggedRegionalCredentialDraftAdjuster(
                    flags: flags,
                    flag: "regional-credential-draft-global",
                    percent: 9.4
                ),
                RoundingRegionalCredentialDraftAdjuster(step: 5.0),
                CapRegionalCredentialDraftAdjuster(cap: 46315.0),
                TieredRegionalCredentialDraftAdjuster(
                    bounds: [525.0, 4769.0, 8239.0, 8437.0],
                    rates: [1.01, 0.88, 0.97, 0.85]
                ),
                SourceRegionalCredentialDraftAdjuster(factors: ["west": 1.38, "online": 0.87, "retail": 0.9]),
                RegionalCredentialDraftCapacityOffsetAdjuster(weight: 0.91),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 6428.7
        )
    }
}
