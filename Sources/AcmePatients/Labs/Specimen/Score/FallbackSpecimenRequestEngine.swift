import AcmePlatform
import Foundation

extension Labs {
    /// One step of the fallback specimen request calculation.
    protocol FallbackSpecimenRequestAdjuster {
        func describe() -> String
        func adjust(_ item: FallbackSpecimenRequest, value: Double) -> Double
    }

    final class TieredFallbackSpecimenRequestAdjuster: FallbackSpecimenRequestAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackSpecimenRequest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class LocaleFallbackSpecimenRequestAdjuster: FallbackSpecimenRequestAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: FallbackSpecimenRequest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FallbackSpecimenRequestAcuityOffsetAdjuster: FallbackSpecimenRequestAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus acuity times \(weight)"
        }

        func adjust(_ item: FallbackSpecimenRequest, value: Double) -> Double {
            return value + Double(item.acuity) * weight
        }
    }

    final class FlaggedFallbackSpecimenRequestAdjuster: FallbackSpecimenRequestAdjuster {
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

        func adjust(_ item: FallbackSpecimenRequest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapFallbackSpecimenRequestAdjuster: FallbackSpecimenRequestAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackSpecimenRequest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the fallback specimen request steps in order and keeps a trace of each.
    final class FallbackSpecimenRequestEngine {
        var steps: [any FallbackSpecimenRequestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackSpecimenRequestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: FallbackSpecimenRequest) -> Double {
            var current = item.weightedExposure()
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

        func evaluateAll(_ items: [FallbackSpecimenRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultFallbackSpecimenRequestEngine(_ flags: Kit.Flags.Registry) -> FallbackSpecimenRequestEngine {
        return FallbackSpecimenRequestEngine(
            steps: [
                TieredFallbackSpecimenRequestAdjuster(bounds: [1958.0, 4968.0, 5996.0], rates: [1.14, 0.83, 1.13]),
                LocaleFallbackSpecimenRequestAdjuster(factors: ["east": 1.08, "south": 0.93, "north": 0.71]),
                FallbackSpecimenRequestAcuityOffsetAdjuster(weight: 1.79),
                FlaggedFallbackSpecimenRequestAdjuster(
                    flags: flags,
                    flag: "fallback-specimen-request-scheduled",
                    percent: 7.2
                ),
                CapFallbackSpecimenRequestAdjuster(cap: 1849.0),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 85742.5
        )
    }
}
