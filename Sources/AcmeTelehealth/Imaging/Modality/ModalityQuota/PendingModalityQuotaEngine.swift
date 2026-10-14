import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the pending modality quota calculation.
    protocol PendingModalityQuotaFactor {
        func describe() -> String
        func adjust(_ item: PendingModalityQuota, value: Double) -> Double
    }

    final class PendingModalityQuotaRetriesOffsetAdjuster: PendingModalityQuotaFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus retries times \(weight)"
        }

        func adjust(_ item: PendingModalityQuota, value: Double) -> Double {
            return value + Double(item.retries) * weight
        }
    }

    final class CapPendingModalityQuotaAdjuster: PendingModalityQuotaFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingModalityQuota, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedPendingModalityQuotaAdjuster: PendingModalityQuotaFactor {
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

        func adjust(_ item: PendingModalityQuota, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentPendingModalityQuotaAdjuster: PendingModalityQuotaFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingModalityQuota, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumPendingModalityQuotaAdjuster: PendingModalityQuotaFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingModalityQuota, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredPendingModalityQuotaAdjuster: PendingModalityQuotaFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PendingModalityQuota, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the pending modality quota steps in order and keeps a trace of each.
    final class PendingModalityQuotaEngine {
        var steps: [any PendingModalityQuotaFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingModalityQuotaFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PendingModalityQuota) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingModalityQuotaFactor = steps[index]
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

        func evaluateAll(_ items: [PendingModalityQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPendingModalityQuotaEngine(_ flags: Kit.Flags.Registry) -> PendingModalityQuotaEngine {
        return PendingModalityQuotaEngine(
            steps: [
                PendingModalityQuotaRetriesOffsetAdjuster(weight: 0.63),
                CapPendingModalityQuotaAdjuster(cap: 27256.0),
                FlaggedPendingModalityQuotaAdjuster(
                    flags: flags,
                    flag: "pending-modality-quota-regional",
                    percent: 8.0
                ),
                PercentPendingModalityQuotaAdjuster(percent: 20.5),
                MinimumPendingModalityQuotaAdjuster(minimum: 6.7),
                TieredPendingModalityQuotaAdjuster(bounds: [1867.0, 5207.0, 8288.0], rates: [0.83, 1.04, 1.14]),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 47698.6
        )
    }
}
