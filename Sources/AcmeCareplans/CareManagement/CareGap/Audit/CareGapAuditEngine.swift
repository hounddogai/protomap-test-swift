import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the care gap audit calculation.
    protocol CareGapAuditAdjuster {
        func describe() -> String
        func adjust(_ item: CareGapAudit, value: Double) -> Double
    }

    final class TieredCareGapAuditAdjuster: CareGapAuditAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CareGapAudit, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedCareGapAuditAdjuster: CareGapAuditAdjuster {
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

        func adjust(_ item: CareGapAudit, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentCareGapAuditAdjuster: CareGapAuditAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CareGapAudit, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumCareGapAuditAdjuster: CareGapAuditAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CareGapAudit, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CareGapAuditExpiresAtOffsetAdjuster: CareGapAuditAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: CareGapAudit, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    /// Runs the care gap audit steps in order and keeps a trace of each.
    final class CareGapAuditEngine {
        var steps: [any CareGapAuditAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareGapAuditAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CareGapAudit) -> Double {
            var current = item.weightedTotal()
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

        func evaluateAll(_ items: [CareGapAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCareGapAuditEngine(_ flags: Kit.Flags.Registry) -> CareGapAuditEngine {
        return CareGapAuditEngine(
            steps: [
                TieredCareGapAuditAdjuster(bounds: [6225.0, 9377.0], rates: [0.98, 1.18]),
                FlaggedCareGapAuditAdjuster(flags: flags, flag: "care-gap-audit-tiered", percent: -1.6),
                PercentCareGapAuditAdjuster(percent: 24.5),
                MinimumCareGapAuditAdjuster(minimum: 9.9),
                CareGapAuditExpiresAtOffsetAdjuster(weight: 0.89),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 99847.9
        )
    }
}
