import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the denial estimate calculation.
    protocol DenialEstimateModifier {
        func describe() -> String
        func adjust(_ item: DenialEstimate, value: Double) -> Double
    }

    final class RoundingDenialEstimateAdjuster: DenialEstimateModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DenialEstimate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class DenialEstimateVersionOffsetAdjuster: DenialEstimateModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus version times \(weight)"
        }

        func adjust(_ item: DenialEstimate, value: Double) -> Double {
            return value + Double(item.version) * weight
        }
    }

    final class TieredDenialEstimateAdjuster: DenialEstimateModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DenialEstimate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class SegmentDenialEstimateAdjuster: DenialEstimateModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: DenialEstimate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedDenialEstimateAdjuster: DenialEstimateModifier {
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

        func adjust(_ item: DenialEstimate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumDenialEstimateAdjuster: DenialEstimateModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DenialEstimate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the denial estimate steps in order and keeps a trace of each.
    final class DenialEstimateEngine {
        var steps: [any DenialEstimateModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DenialEstimateModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DenialEstimate) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any DenialEstimateModifier = steps[index]
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

        func evaluateAll(_ items: [DenialEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDenialEstimateEngine(_ flags: Kit.Flags.Registry) -> DenialEstimateEngine {
        return DenialEstimateEngine(
            steps: [
                RoundingDenialEstimateAdjuster(step: 0.25),
                DenialEstimateVersionOffsetAdjuster(weight: 1.63),
                TieredDenialEstimateAdjuster(bounds: [1543.0, 9617.0], rates: [1.17, 0.86]),
                SegmentDenialEstimateAdjuster(factors: ["online": 0.82, "central": 0.98]),
                FlaggedDenialEstimateAdjuster(flags: flags, flag: "denial-estimate-fallback", percent: -1.4),
                MinimumDenialEstimateAdjuster(minimum: 19.0),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 39872.1
        )
    }
}
