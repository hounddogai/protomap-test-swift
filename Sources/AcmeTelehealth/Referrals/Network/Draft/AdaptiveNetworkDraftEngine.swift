import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the adaptive network draft calculation.
    protocol AdaptiveNetworkDraftAdjuster {
        func describe() -> String
        func adjust(_ item: AdaptiveNetworkDraft, value: Double) -> Double
    }

    final class MinimumAdaptiveNetworkDraftAdjuster: AdaptiveNetworkDraftAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveNetworkDraft, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredAdaptiveNetworkDraftAdjuster: AdaptiveNetworkDraftAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveNetworkDraft, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CategoryAdaptiveNetworkDraftAdjuster: AdaptiveNetworkDraftAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: AdaptiveNetworkDraft, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedAdaptiveNetworkDraftAdjuster: AdaptiveNetworkDraftAdjuster {
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

        func adjust(_ item: AdaptiveNetworkDraft, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class AdaptiveNetworkDraftCapacityOffsetAdjuster: AdaptiveNetworkDraftAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: AdaptiveNetworkDraft, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    final class CapAdaptiveNetworkDraftAdjuster: AdaptiveNetworkDraftAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveNetworkDraft, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the adaptive network draft steps in order and keeps a trace of each.
    final class AdaptiveNetworkDraftEngine {
        var steps: [any AdaptiveNetworkDraftAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveNetworkDraftAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AdaptiveNetworkDraft) -> Double {
            var current = item.weightedValue()
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

        func evaluateAll(_ items: [AdaptiveNetworkDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAdaptiveNetworkDraftEngine(_ flags: Kit.Flags.Registry) -> AdaptiveNetworkDraftEngine {
        return AdaptiveNetworkDraftEngine(
            steps: [
                MinimumAdaptiveNetworkDraftAdjuster(minimum: 25.5),
                TieredAdaptiveNetworkDraftAdjuster(bounds: [2253.0, 5276.0], rates: [1.04, 1.09]),
                CategoryAdaptiveNetworkDraftAdjuster(factors: ["south": 1.19, "retail": 1.01]),
                FlaggedAdaptiveNetworkDraftAdjuster(
                    flags: flags,
                    flag: "adaptive-network-draft-fallback",
                    percent: 5.3
                ),
                AdaptiveNetworkDraftCapacityOffsetAdjuster(weight: 1.34),
                CapAdaptiveNetworkDraftAdjuster(cap: 43771.0),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 94057.8
        )
    }
}
