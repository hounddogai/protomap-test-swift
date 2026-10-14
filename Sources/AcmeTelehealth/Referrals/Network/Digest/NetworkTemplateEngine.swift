import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the network template calculation.
    protocol NetworkTemplateModifier {
        func describe() -> String
        func adjust(_ item: NetworkTemplate, value: Double) -> Double
    }

    final class RoundingNetworkTemplateAdjuster: NetworkTemplateModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: NetworkTemplate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class RegionNetworkTemplateAdjuster: NetworkTemplateModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: NetworkTemplate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumNetworkTemplateAdjuster: NetworkTemplateModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: NetworkTemplate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedNetworkTemplateAdjuster: NetworkTemplateModifier {
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

        func adjust(_ item: NetworkTemplate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentNetworkTemplateAdjuster: NetworkTemplateModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: NetworkTemplate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapNetworkTemplateAdjuster: NetworkTemplateModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: NetworkTemplate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the network template steps in order and keeps a trace of each.
    final class NetworkTemplateEngine {
        var steps: [any NetworkTemplateModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any NetworkTemplateModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: NetworkTemplate) -> Double {
            var current = item.effectiveValue()
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

        func evaluateAll(_ items: [NetworkTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultNetworkTemplateEngine(_ flags: Kit.Flags.Registry) -> NetworkTemplateEngine {
        return NetworkTemplateEngine(
            steps: [
                RoundingNetworkTemplateAdjuster(step: 0.05),
                RegionNetworkTemplateAdjuster(factors: ["north": 0.78]),
                MinimumNetworkTemplateAdjuster(minimum: 49.2),
                FlaggedNetworkTemplateAdjuster(flags: flags, flag: "network-template-rolling", percent: 4.7),
                PercentNetworkTemplateAdjuster(percent: -12.9),
                CapNetworkTemplateAdjuster(cap: 1775.0),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 35606.9
        )
    }
}
