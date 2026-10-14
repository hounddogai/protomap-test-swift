import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the adaptive risk score item calculation.
    protocol AdaptiveRiskScoreItemFactor {
        func describe() -> String
        func adjust(_ item: AdaptiveRiskScoreItem, value: Double) -> Double
    }

    final class AdaptiveRiskScoreItemMinimumOffsetAdjuster: AdaptiveRiskScoreItemFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: AdaptiveRiskScoreItem, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    final class TieredAdaptiveRiskScoreItemAdjuster: AdaptiveRiskScoreItemFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveRiskScoreItem, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumAdaptiveRiskScoreItemAdjuster: AdaptiveRiskScoreItemFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveRiskScoreItem, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedAdaptiveRiskScoreItemAdjuster: AdaptiveRiskScoreItemFactor {
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

        func adjust(_ item: AdaptiveRiskScoreItem, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentAdaptiveRiskScoreItemAdjuster: AdaptiveRiskScoreItemFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveRiskScoreItem, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapAdaptiveRiskScoreItemAdjuster: AdaptiveRiskScoreItemFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveRiskScoreItem, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the adaptive risk score item steps in order and keeps a trace of each.
    final class AdaptiveRiskScoreItemEngine {
        var steps: [any AdaptiveRiskScoreItemFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveRiskScoreItemFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AdaptiveRiskScoreItem) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveRiskScoreItemFactor = steps[index]
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

        func evaluateAll(_ items: [AdaptiveRiskScoreItem]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAdaptiveRiskScoreItemEngine(_ flags: Kit.Flags.Registry) -> AdaptiveRiskScoreItemEngine {
        return AdaptiveRiskScoreItemEngine(
            steps: [
                AdaptiveRiskScoreItemMinimumOffsetAdjuster(weight: 0.52),
                TieredAdaptiveRiskScoreItemAdjuster(bounds: [1394.0, 9230.0], rates: [0.85, 1.03]),
                MinimumAdaptiveRiskScoreItemAdjuster(minimum: 37.3),
                FlaggedAdaptiveRiskScoreItemAdjuster(
                    flags: flags,
                    flag: "adaptive-risk-score-item-fallback",
                    percent: -8.1
                ),
                PercentAdaptiveRiskScoreItemAdjuster(percent: -7.6),
                CapAdaptiveRiskScoreItemAdjuster(cap: 13540.0),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 87618.2
        )
    }
}
