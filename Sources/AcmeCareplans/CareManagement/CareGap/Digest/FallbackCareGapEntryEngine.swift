import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the fallback care gap entry calculation.
    protocol FallbackCareGapEntryModifier {
        func describe() -> String
        func adjust(_ item: FallbackCareGapEntry, value: Double) -> Double
    }

    final class TieredFallbackCareGapEntryAdjuster: FallbackCareGapEntryModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackCareGapEntry, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedFallbackCareGapEntryAdjuster: FallbackCareGapEntryModifier {
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

        func adjust(_ item: FallbackCareGapEntry, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentFallbackCareGapEntryAdjuster: FallbackCareGapEntryModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackCareGapEntry, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FallbackCareGapEntryMarginOffsetAdjuster: FallbackCareGapEntryModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus margin times \(weight)"
        }

        func adjust(_ item: FallbackCareGapEntry, value: Double) -> Double {
            return value + item.margin * weight
        }
    }

    final class CapFallbackCareGapEntryAdjuster: FallbackCareGapEntryModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackCareGapEntry, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the fallback care gap entry steps in order and keeps a trace of each.
    final class FallbackCareGapEntryEngine {
        var steps: [any FallbackCareGapEntryModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackCareGapEntryModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: FallbackCareGapEntry) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackCareGapEntryModifier = steps[index]
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

        func evaluateAll(_ items: [FallbackCareGapEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultFallbackCareGapEntryEngine(_ flags: Kit.Flags.Registry) -> FallbackCareGapEntryEngine {
        return FallbackCareGapEntryEngine(
            steps: [
                TieredFallbackCareGapEntryAdjuster(bounds: [241.0, 415.0, 1139.0], rates: [1.07, 0.85, 0.99]),
                FlaggedFallbackCareGapEntryAdjuster(
                    flags: flags,
                    flag: "fallback-care-gap-entry-fallback",
                    percent: 3.7
                ),
                PercentFallbackCareGapEntryAdjuster(percent: 12.8),
                FallbackCareGapEntryMarginOffsetAdjuster(weight: 1.78),
                CapFallbackCareGapEntryAdjuster(cap: 39322.0),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 23997.3
        )
    }
}
