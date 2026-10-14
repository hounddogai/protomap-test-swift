import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the remittance override calculation.
    protocol RemittanceOverrideAdjuster {
        func describe() -> String
        func adjust(_ item: RemittanceOverride, value: Double) -> Double
    }

    final class CapRemittanceOverrideAdjuster: RemittanceOverrideAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RemittanceOverride, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedRemittanceOverrideAdjuster: RemittanceOverrideAdjuster {
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

        func adjust(_ item: RemittanceOverride, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumRemittanceOverrideAdjuster: RemittanceOverrideAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RemittanceOverride, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LabelRemittanceOverrideAdjuster: RemittanceOverrideAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: RemittanceOverride, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredRemittanceOverrideAdjuster: RemittanceOverrideAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RemittanceOverride, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RemittanceOverrideVisitMinutesOffsetAdjuster: RemittanceOverrideAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus visit minutes times \(weight)"
        }

        func adjust(_ item: RemittanceOverride, value: Double) -> Double {
            return value + Double(item.visitMinutes) * weight
        }
    }

    /// Runs the remittance override steps in order and keeps a trace of each.
    final class RemittanceOverrideEngine {
        var steps: [any RemittanceOverrideAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RemittanceOverrideAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RemittanceOverride) -> Double {
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

        func evaluateAll(_ items: [RemittanceOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRemittanceOverrideEngine(_ flags: Kit.Flags.Registry) -> RemittanceOverrideEngine {
        return RemittanceOverrideEngine(
            steps: [
                CapRemittanceOverrideAdjuster(cap: 3840.0),
                FlaggedRemittanceOverrideAdjuster(flags: flags, flag: "remittance-override-strict", percent: 3.6),
                MinimumRemittanceOverrideAdjuster(minimum: 31.7),
                LabelRemittanceOverrideAdjuster(factors: ["retail": 0.94, "south": 0.77, "central": 0.8]),
                TieredRemittanceOverrideAdjuster(
                    bounds: [2068.0, 6936.0, 7111.0, 8191.0],
                    rates: [1.05, 1.02, 0.87, 0.9]
                ),
                RemittanceOverrideVisitMinutesOffsetAdjuster(weight: 1.87),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 72147.3
        )
    }
}
