import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the cleaning quota calculation.
    protocol CleaningQuotaFactor {
        func describe() -> String
        func adjust(_ item: CleaningQuota, value: Double) -> Double
    }

    final class FlaggedCleaningQuotaAdjuster: CleaningQuotaFactor {
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

        func adjust(_ item: CleaningQuota, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapCleaningQuotaAdjuster: CleaningQuotaFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CleaningQuota, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredCleaningQuotaAdjuster: CleaningQuotaFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CleaningQuota, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class SegmentCleaningQuotaAdjuster: CleaningQuotaFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: CleaningQuota, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the cleaning quota steps in order and keeps a trace of each.
    final class CleaningQuotaEngine {
        var steps: [any CleaningQuotaFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CleaningQuotaFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CleaningQuota) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any CleaningQuotaFactor = steps[index]
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

        func evaluateAll(_ items: [CleaningQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCleaningQuotaEngine(_ flags: Kit.Flags.Registry) -> CleaningQuotaEngine {
        return CleaningQuotaEngine(
            steps: [
                FlaggedCleaningQuotaAdjuster(flags: flags, flag: "cleaning-quota-primary", percent: 3.0),
                CapCleaningQuotaAdjuster(cap: 14041.0),
                TieredCleaningQuotaAdjuster(bounds: [946.0, 1340.0, 9022.0, 9595.0], rates: [1.17, 1.1, 0.8, 1.08]),
                SegmentCleaningQuotaAdjuster(factors: ["central": 0.89, "online": 0.85]),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 32252.2
        )
    }
}
