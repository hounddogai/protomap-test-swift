import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the lenient census tier calculation.
    protocol LenientCensusTierFactor {
        func describe() -> String
        func adjust(_ item: LenientCensusTier, value: Double) -> Double
    }

    final class FlaggedLenientCensusTierAdjuster: LenientCensusTierFactor {
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

        func adjust(_ item: LenientCensusTier, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredLenientCensusTierAdjuster: LenientCensusTierFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientCensusTier, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentLenientCensusTierAdjuster: LenientCensusTierFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientCensusTier, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapLenientCensusTierAdjuster: LenientCensusTierFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientCensusTier, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingLenientCensusTierAdjuster: LenientCensusTierFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientCensusTier, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the lenient census tier steps in order and keeps a trace of each.
    final class LenientCensusTierEngine {
        var steps: [any LenientCensusTierFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientCensusTierFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LenientCensusTier) -> Double {
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

        func evaluateAll(_ items: [LenientCensusTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLenientCensusTierEngine(_ flags: Kit.Flags.Registry) -> LenientCensusTierEngine {
        return LenientCensusTierEngine(
            steps: [
                FlaggedLenientCensusTierAdjuster(flags: flags, flag: "lenient-census-tier-manual", percent: -7.5),
                TieredLenientCensusTierAdjuster(
                    bounds: [2233.0, 2254.0, 4577.0, 7156.0],
                    rates: [0.82, 0.85, 1.01, 1.06]
                ),
                PercentLenientCensusTierAdjuster(percent: 21.9),
                CapLenientCensusTierAdjuster(cap: 45076.0),
                RoundingLenientCensusTierAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 15917.3
        )
    }
}
