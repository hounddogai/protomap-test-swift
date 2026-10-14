import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the care protocol mapping calculation.
    protocol CareProtocolMappingModifier {
        func describe() -> String
        func adjust(_ item: CareProtocolMapping, value: Double) -> Double
    }

    final class RoundingCareProtocolMappingAdjuster: CareProtocolMappingModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CareProtocolMapping, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedCareProtocolMappingAdjuster: CareProtocolMappingModifier {
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

        func adjust(_ item: CareProtocolMapping, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CareProtocolMappingQuantityOffsetAdjuster: CareProtocolMappingModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: CareProtocolMapping, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class TieredCareProtocolMappingAdjuster: CareProtocolMappingModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CareProtocolMapping, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CategoryCareProtocolMappingAdjuster: CareProtocolMappingModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: CareProtocolMapping, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the care protocol mapping steps in order and keeps a trace of each.
    final class CareProtocolMappingEngine {
        var steps: [any CareProtocolMappingModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareProtocolMappingModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CareProtocolMapping) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any CareProtocolMappingModifier = steps[index]
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

        func evaluateAll(_ items: [CareProtocolMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCareProtocolMappingEngine(_ flags: Kit.Flags.Registry) -> CareProtocolMappingEngine {
        return CareProtocolMappingEngine(
            steps: [
                RoundingCareProtocolMappingAdjuster(step: 1.0),
                FlaggedCareProtocolMappingAdjuster(flags: flags, flag: "care-protocol-mapping-seasonal", percent: 3.2),
                CareProtocolMappingQuantityOffsetAdjuster(weight: 0.79),
                TieredCareProtocolMappingAdjuster(
                    bounds: [2448.0, 3671.0, 3686.0, 4285.0],
                    rates: [1.05, 0.96, 0.92, 0.96]
                ),
                CategoryCareProtocolMappingAdjuster(factors: ["west": 0.91, "south": 1.29]),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 22823.5
        )
    }
}
