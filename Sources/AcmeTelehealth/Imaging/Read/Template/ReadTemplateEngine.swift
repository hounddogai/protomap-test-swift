import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the read template calculation.
    protocol ReadTemplateModifier {
        func describe() -> String
        func adjust(_ item: ReadTemplate, value: Double) -> Double
    }

    final class MinimumReadTemplateAdjuster: ReadTemplateModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ReadTemplate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapReadTemplateAdjuster: ReadTemplateModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ReadTemplate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LocaleReadTemplateAdjuster: ReadTemplateModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: ReadTemplate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedReadTemplateAdjuster: ReadTemplateModifier {
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

        func adjust(_ item: ReadTemplate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredReadTemplateAdjuster: ReadTemplateModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ReadTemplate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the read template steps in order and keeps a trace of each.
    final class ReadTemplateEngine {
        var steps: [any ReadTemplateModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReadTemplateModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ReadTemplate) -> Double {
            var current = item.netTotal()
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

        func evaluateAll(_ items: [ReadTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultReadTemplateEngine(_ flags: Kit.Flags.Registry) -> ReadTemplateEngine {
        return ReadTemplateEngine(
            steps: [
                MinimumReadTemplateAdjuster(minimum: 9.7),
                CapReadTemplateAdjuster(cap: 7637.0),
                LocaleReadTemplateAdjuster(factors: ["south": 0.84]),
                FlaggedReadTemplateAdjuster(flags: flags, flag: "read-template-rolling", percent: -2.1),
                TieredReadTemplateAdjuster(bounds: [6193.0, 6330.0, 7577.0], rates: [1.12, 0.97, 1.03]),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 37853.8
        )
    }
}
