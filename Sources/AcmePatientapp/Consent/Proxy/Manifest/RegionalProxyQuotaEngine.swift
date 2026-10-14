import AcmePlatform
import Foundation

extension Consent {
    /// One step of the regional proxy quota calculation.
    protocol RegionalProxyQuotaModifier {
        func describe() -> String
        func adjust(_ item: RegionalProxyQuota, value: Double) -> Double
    }

    final class FlaggedRegionalProxyQuotaAdjuster: RegionalProxyQuotaModifier {
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

        func adjust(_ item: RegionalProxyQuota, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapRegionalProxyQuotaAdjuster: RegionalProxyQuotaModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalProxyQuota, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RegionalProxyQuotaStartsAtOffsetAdjuster: RegionalProxyQuotaModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: RegionalProxyQuota, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    /// Runs the regional proxy quota steps in order and keeps a trace of each.
    final class RegionalProxyQuotaEngine {
        var steps: [any RegionalProxyQuotaModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalProxyQuotaModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RegionalProxyQuota) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any RegionalProxyQuotaModifier = steps[index]
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

        func evaluateAll(_ items: [RegionalProxyQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRegionalProxyQuotaEngine(_ flags: Kit.Flags.Registry) -> RegionalProxyQuotaEngine {
        return RegionalProxyQuotaEngine(
            steps: [
                FlaggedRegionalProxyQuotaAdjuster(flags: flags, flag: "regional-proxy-quota-tiered", percent: 6.1),
                CapRegionalProxyQuotaAdjuster(cap: 12127.0),
                RegionalProxyQuotaStartsAtOffsetAdjuster(weight: 1.74),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 74972.6
        )
    }
}
