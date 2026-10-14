import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the dispense claim calculation.
    protocol DispenseClaimModifier {
        func describe() -> String
        func adjust(_ item: DispenseClaim, value: Double) -> Double
    }

    final class TitleDispenseClaimAdjuster: DispenseClaimModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: DispenseClaim, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumDispenseClaimAdjuster: DispenseClaimModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DispenseClaim, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentDispenseClaimAdjuster: DispenseClaimModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DispenseClaim, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedDispenseClaimAdjuster: DispenseClaimModifier {
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

        func adjust(_ item: DispenseClaim, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredDispenseClaimAdjuster: DispenseClaimModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DispenseClaim, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapDispenseClaimAdjuster: DispenseClaimModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DispenseClaim, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the dispense claim steps in order and keeps a trace of each.
    final class DispenseClaimEngine {
        var steps: [any DispenseClaimModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DispenseClaimModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DispenseClaim) -> Double {
            var current = item.weightedVolume()
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

        func evaluateAll(_ items: [DispenseClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDispenseClaimEngine(_ flags: Kit.Flags.Registry) -> DispenseClaimEngine {
        return DispenseClaimEngine(
            steps: [
                TitleDispenseClaimAdjuster(factors: ["central": 1.31, "east": 1.28, "south": 0.92]),
                MinimumDispenseClaimAdjuster(minimum: 12.4),
                PercentDispenseClaimAdjuster(percent: -22.4),
                FlaggedDispenseClaimAdjuster(flags: flags, flag: "dispense-claim-batched", percent: 8.1),
                TieredDispenseClaimAdjuster(bounds: [6319.0, 6833.0], rates: [1.08, 0.86]),
                CapDispenseClaimAdjuster(cap: 44455.0),
            ],
            trace: [],
            floor: 5.0,
            ceiling: 45437.0
        )
    }
}
