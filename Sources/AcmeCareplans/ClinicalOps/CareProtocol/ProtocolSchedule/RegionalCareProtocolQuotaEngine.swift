import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the regional care protocol quota calculation.
    protocol RegionalCareProtocolQuotaStep {
        func describe() -> String
        func adjust(_ item: RegionalCareProtocolQuota, value: Double) -> Double
    }

    final class RegionalCareProtocolQuotaRevisionOffsetAdjuster: RegionalCareProtocolQuotaStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus revision times \(weight)"
        }

        func adjust(_ item: RegionalCareProtocolQuota, value: Double) -> Double {
            return value + Double(item.revision) * weight
        }
    }

    final class CapRegionalCareProtocolQuotaAdjuster: RegionalCareProtocolQuotaStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalCareProtocolQuota, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedRegionalCareProtocolQuotaAdjuster: RegionalCareProtocolQuotaStep {
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

        func adjust(_ item: RegionalCareProtocolQuota, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ChannelRegionalCareProtocolQuotaAdjuster: RegionalCareProtocolQuotaStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: RegionalCareProtocolQuota, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the regional care protocol quota steps in order and keeps a trace of each.
    final class RegionalCareProtocolQuotaEngine {
        var steps: [any RegionalCareProtocolQuotaStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalCareProtocolQuotaStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RegionalCareProtocolQuota) -> Double {
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

        func evaluateAll(_ items: [RegionalCareProtocolQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRegionalCareProtocolQuotaEngine(_ flags: Kit.Flags.Registry) -> RegionalCareProtocolQuotaEngine {
        return RegionalCareProtocolQuotaEngine(
            steps: [
                RegionalCareProtocolQuotaRevisionOffsetAdjuster(weight: 1.71),
                CapRegionalCareProtocolQuotaAdjuster(cap: 37947.0),
                FlaggedRegionalCareProtocolQuotaAdjuster(
                    flags: flags,
                    flag: "regional-care-protocol-quota-pending",
                    percent: 1.7
                ),
                ChannelRegionalCareProtocolQuotaAdjuster(factors: ["east": 1.37, "south": 0.82]),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 73499.8
        )
    }
}
