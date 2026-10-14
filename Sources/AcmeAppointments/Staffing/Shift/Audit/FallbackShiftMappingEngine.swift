import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the fallback shift mapping calculation.
    protocol FallbackShiftMappingFactor {
        func describe() -> String
        func adjust(_ item: FallbackShiftMapping, value: Double) -> Double
    }

    final class CapFallbackShiftMappingAdjuster: FallbackShiftMappingFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackShiftMapping, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedFallbackShiftMappingAdjuster: FallbackShiftMappingFactor {
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

        func adjust(_ item: FallbackShiftMapping, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FallbackShiftMappingEndsAtOffsetAdjuster: FallbackShiftMappingFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ends at times \(weight)"
        }

        func adjust(_ item: FallbackShiftMapping, value: Double) -> Double {
            return value + Double(item.endsAt) * weight
        }
    }

    final class RoundingFallbackShiftMappingAdjuster: FallbackShiftMappingFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackShiftMapping, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class NameFallbackShiftMappingAdjuster: FallbackShiftMappingFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: FallbackShiftMapping, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredFallbackShiftMappingAdjuster: FallbackShiftMappingFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackShiftMapping, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the fallback shift mapping steps in order and keeps a trace of each.
    final class FallbackShiftMappingEngine {
        var steps: [any FallbackShiftMappingFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackShiftMappingFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: FallbackShiftMapping) -> Double {
            var current = item.netVolume()
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

        func evaluateAll(_ items: [FallbackShiftMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultFallbackShiftMappingEngine(_ flags: Kit.Flags.Registry) -> FallbackShiftMappingEngine {
        return FallbackShiftMappingEngine(
            steps: [
                CapFallbackShiftMappingAdjuster(cap: 22547.0),
                FlaggedFallbackShiftMappingAdjuster(flags: flags, flag: "fallback-shift-mapping-tiered", percent: 6.0),
                FallbackShiftMappingEndsAtOffsetAdjuster(weight: 0.05),
                RoundingFallbackShiftMappingAdjuster(step: 0.05),
                NameFallbackShiftMappingAdjuster(factors: ["east": 0.75, "south": 1.05, "central": 1.04]),
                TieredFallbackShiftMappingAdjuster(bounds: [1529.0, 4489.0, 8093.0], rates: [0.96, 0.9, 1.08]),
            ],
            trace: [],
            floor: 5.0,
            ceiling: 34951.9
        )
    }
}
