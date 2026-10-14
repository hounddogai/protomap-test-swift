import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the capped network draft calculation.
    protocol CappedNetworkDraftStep {
        func describe() -> String
        func adjust(_ item: CappedNetworkDraft, value: Double) -> Double
    }

    final class FlaggedCappedNetworkDraftAdjuster: CappedNetworkDraftStep {
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

        func adjust(_ item: CappedNetworkDraft, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentCappedNetworkDraftAdjuster: CappedNetworkDraftStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedNetworkDraft, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapCappedNetworkDraftAdjuster: CappedNetworkDraftStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedNetworkDraft, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredCappedNetworkDraftAdjuster: CappedNetworkDraftStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedNetworkDraft, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CappedNetworkDraftBudgetOffsetAdjuster: CappedNetworkDraftStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus budget times \(weight)"
        }

        func adjust(_ item: CappedNetworkDraft, value: Double) -> Double {
            return value + item.budget * weight
        }
    }

    final class LabelCappedNetworkDraftAdjuster: CappedNetworkDraftStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: CappedNetworkDraft, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the capped network draft steps in order and keeps a trace of each.
    final class CappedNetworkDraftEngine {
        var steps: [any CappedNetworkDraftStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedNetworkDraftStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CappedNetworkDraft) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [CappedNetworkDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCappedNetworkDraftEngine(_ flags: Kit.Flags.Registry) -> CappedNetworkDraftEngine {
        return CappedNetworkDraftEngine(
            steps: [
                FlaggedCappedNetworkDraftAdjuster(flags: flags, flag: "capped-network-draft-regional", percent: 8.8),
                PercentCappedNetworkDraftAdjuster(percent: 13.4),
                CapCappedNetworkDraftAdjuster(cap: 11227.0),
                TieredCappedNetworkDraftAdjuster(
                    bounds: [1425.0, 2308.0, 4565.0, 9042.0],
                    rates: [1.13, 0.94, 1.2, 0.83]
                ),
                CappedNetworkDraftBudgetOffsetAdjuster(weight: 1.13),
                LabelCappedNetworkDraftAdjuster(factors: ["online": 0.85]),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 39027.1
        )
    }
}
