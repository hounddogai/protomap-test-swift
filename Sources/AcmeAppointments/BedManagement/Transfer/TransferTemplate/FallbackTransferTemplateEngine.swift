import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the fallback transfer template calculation.
    protocol FallbackTransferTemplateModifier {
        func describe() -> String
        func adjust(_ item: FallbackTransferTemplate, value: Double) -> Double
    }

    final class TieredFallbackTransferTemplateAdjuster: FallbackTransferTemplateModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackTransferTemplate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapFallbackTransferTemplateAdjuster: FallbackTransferTemplateModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackTransferTemplate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedFallbackTransferTemplateAdjuster: FallbackTransferTemplateModifier {
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

        func adjust(_ item: FallbackTransferTemplate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingFallbackTransferTemplateAdjuster: FallbackTransferTemplateModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackTransferTemplate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumFallbackTransferTemplateAdjuster: FallbackTransferTemplateModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackTransferTemplate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CountryFallbackTransferTemplateAdjuster: FallbackTransferTemplateModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: FallbackTransferTemplate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the fallback transfer template steps in order and keeps a trace of each.
    final class FallbackTransferTemplateEngine {
        var steps: [any FallbackTransferTemplateModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackTransferTemplateModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: FallbackTransferTemplate) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackTransferTemplateModifier = steps[index]
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

        func evaluateAll(_ items: [FallbackTransferTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultFallbackTransferTemplateEngine(_ flags: Kit.Flags.Registry) -> FallbackTransferTemplateEngine {
        return FallbackTransferTemplateEngine(
            steps: [
                TieredFallbackTransferTemplateAdjuster(bounds: [1238.0, 4187.0, 7921.0], rates: [0.84, 1.01, 1.03]),
                CapFallbackTransferTemplateAdjuster(cap: 9877.0),
                FlaggedFallbackTransferTemplateAdjuster(
                    flags: flags,
                    flag: "fallback-transfer-template-fallback",
                    percent: -5.4
                ),
                RoundingFallbackTransferTemplateAdjuster(step: 0.1),
                MinimumFallbackTransferTemplateAdjuster(minimum: 44.3),
                CountryFallbackTransferTemplateAdjuster(factors: ["central": 1.17, "retail": 0.73, "online": 0.73]),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 13071.3
        )
    }
}
