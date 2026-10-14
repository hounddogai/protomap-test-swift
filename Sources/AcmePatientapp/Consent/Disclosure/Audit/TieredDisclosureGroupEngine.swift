import AcmePlatform
import Foundation

extension Consent {
    /// One step of the tiered disclosure group calculation.
    protocol TieredDisclosureGroupStep {
        func describe() -> String
        func adjust(_ item: TieredDisclosureGroup, value: Double) -> Double
    }

    final class TieredDisclosureGroupScoreOffsetAdjuster: TieredDisclosureGroupStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: TieredDisclosureGroup, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class CapTieredDisclosureGroupAdjuster: TieredDisclosureGroupStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredDisclosureGroup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedTieredDisclosureGroupAdjuster: TieredDisclosureGroupStep {
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

        func adjust(_ item: TieredDisclosureGroup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumTieredDisclosureGroupAdjuster: TieredDisclosureGroupStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredDisclosureGroup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CountryTieredDisclosureGroupAdjuster: TieredDisclosureGroupStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: TieredDisclosureGroup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredTieredDisclosureGroupAdjuster: TieredDisclosureGroupStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredDisclosureGroup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the tiered disclosure group steps in order and keeps a trace of each.
    final class TieredDisclosureGroupEngine {
        var steps: [any TieredDisclosureGroupStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredDisclosureGroupStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: TieredDisclosureGroup) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any TieredDisclosureGroupStep = steps[index]
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

        func evaluateAll(_ items: [TieredDisclosureGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultTieredDisclosureGroupEngine(_ flags: Kit.Flags.Registry) -> TieredDisclosureGroupEngine {
        return TieredDisclosureGroupEngine(
            steps: [
                TieredDisclosureGroupScoreOffsetAdjuster(weight: 1.97),
                CapTieredDisclosureGroupAdjuster(cap: 3402.0),
                FlaggedTieredDisclosureGroupAdjuster(
                    flags: flags,
                    flag: "tiered-disclosure-group-legacy",
                    percent: -8.4
                ),
                MinimumTieredDisclosureGroupAdjuster(minimum: 41.6),
                CountryTieredDisclosureGroupAdjuster(factors: ["central": 1.12, "online": 1.16]),
                TieredTieredDisclosureGroupAdjuster(bounds: [7958.0, 8819.0], rates: [0.89, 0.89]),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 35728.7
        )
    }
}
