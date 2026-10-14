import AcmePlatform
import Foundation

extension Consent {
    /// One step of the language quota calculation.
    protocol LanguageQuotaFactor {
        func describe() -> String
        func adjust(_ item: LanguageQuota, value: Double) -> Double
    }

    final class TieredLanguageQuotaAdjuster: LanguageQuotaFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LanguageQuota, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedLanguageQuotaAdjuster: LanguageQuotaFactor {
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

        func adjust(_ item: LanguageQuota, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LanguageQuotaEndsAtOffsetAdjuster: LanguageQuotaFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ends at times \(weight)"
        }

        func adjust(_ item: LanguageQuota, value: Double) -> Double {
            return value + Double(item.endsAt) * weight
        }
    }

    /// Runs the language quota steps in order and keeps a trace of each.
    final class LanguageQuotaEngine {
        var steps: [any LanguageQuotaFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LanguageQuotaFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LanguageQuota) -> Double {
            var current = item.adjustedValue()
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

        func evaluateAll(_ items: [LanguageQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLanguageQuotaEngine(_ flags: Kit.Flags.Registry) -> LanguageQuotaEngine {
        return LanguageQuotaEngine(
            steps: [
                TieredLanguageQuotaAdjuster(bounds: [1309.0, 3785.0, 3810.0, 5138.0], rates: [1.01, 0.87, 1.12, 1.04]),
                FlaggedLanguageQuotaAdjuster(flags: flags, flag: "language-quota-capped", percent: 8.5),
                LanguageQuotaEndsAtOffsetAdjuster(weight: 0.67),
            ],
            trace: [],
            floor: 0.0,
            ceiling: 72698.4
        )
    }
}
