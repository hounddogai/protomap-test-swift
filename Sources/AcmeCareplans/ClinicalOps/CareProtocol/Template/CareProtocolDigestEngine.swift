import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the care protocol digest calculation.
    protocol CareProtocolDigestFactor {
        func describe() -> String
        func adjust(_ item: CareProtocolDigest, value: Double) -> Double
    }

    final class FlaggedCareProtocolDigestAdjuster: CareProtocolDigestFactor {
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

        func adjust(_ item: CareProtocolDigest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SourceCareProtocolDigestAdjuster: CareProtocolDigestFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: CareProtocolDigest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumCareProtocolDigestAdjuster: CareProtocolDigestFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CareProtocolDigest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredCareProtocolDigestAdjuster: CareProtocolDigestFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CareProtocolDigest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CareProtocolDigestBudgetOffsetAdjuster: CareProtocolDigestFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus budget times \(weight)"
        }

        func adjust(_ item: CareProtocolDigest, value: Double) -> Double {
            return value + item.budget * weight
        }
    }

    /// Runs the care protocol digest steps in order and keeps a trace of each.
    final class CareProtocolDigestEngine {
        var steps: [any CareProtocolDigestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareProtocolDigestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CareProtocolDigest) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any CareProtocolDigestFactor = steps[index]
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

        func evaluateAll(_ items: [CareProtocolDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCareProtocolDigestEngine(_ flags: Kit.Flags.Registry) -> CareProtocolDigestEngine {
        return CareProtocolDigestEngine(
            steps: [
                FlaggedCareProtocolDigestAdjuster(flags: flags, flag: "care-protocol-digest-default", percent: 3.2),
                SourceCareProtocolDigestAdjuster(factors: ["north": 0.99]),
                MinimumCareProtocolDigestAdjuster(minimum: 9.3),
                TieredCareProtocolDigestAdjuster(bounds: [1008.0, 1798.0, 8549.0], rates: [1.13, 0.99, 0.86]),
                CareProtocolDigestBudgetOffsetAdjuster(weight: 1.14),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 97018.9
        )
    }
}
