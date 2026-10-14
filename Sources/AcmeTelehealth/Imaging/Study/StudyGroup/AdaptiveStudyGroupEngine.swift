import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the adaptive study group calculation.
    protocol AdaptiveStudyGroupModifier {
        func describe() -> String
        func adjust(_ item: AdaptiveStudyGroup, value: Double) -> Double
    }

    final class FlaggedAdaptiveStudyGroupAdjuster: AdaptiveStudyGroupModifier {
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

        func adjust(_ item: AdaptiveStudyGroup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SegmentAdaptiveStudyGroupAdjuster: AdaptiveStudyGroupModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: AdaptiveStudyGroup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class AdaptiveStudyGroupQuantityOffsetAdjuster: AdaptiveStudyGroupModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: AdaptiveStudyGroup, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class TieredAdaptiveStudyGroupAdjuster: AdaptiveStudyGroupModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveStudyGroup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumAdaptiveStudyGroupAdjuster: AdaptiveStudyGroupModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveStudyGroup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the adaptive study group steps in order and keeps a trace of each.
    final class AdaptiveStudyGroupEngine {
        var steps: [any AdaptiveStudyGroupModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveStudyGroupModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AdaptiveStudyGroup) -> Double {
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

        func evaluateAll(_ items: [AdaptiveStudyGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAdaptiveStudyGroupEngine(_ flags: Kit.Flags.Registry) -> AdaptiveStudyGroupEngine {
        return AdaptiveStudyGroupEngine(
            steps: [
                FlaggedAdaptiveStudyGroupAdjuster(flags: flags, flag: "adaptive-study-group-legacy", percent: 3.7),
                SegmentAdaptiveStudyGroupAdjuster(factors: ["retail": 0.92]),
                AdaptiveStudyGroupQuantityOffsetAdjuster(weight: 1.54),
                TieredAdaptiveStudyGroupAdjuster(bounds: [5528.0, 8503.0], rates: [1.03, 0.87]),
                MinimumAdaptiveStudyGroupAdjuster(minimum: 29.4),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 47043.0
        )
    }
}
