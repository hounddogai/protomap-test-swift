import AcmePlatform
import Foundation

extension Labs {
    /// One step of the specimen request calculation.
    protocol SpecimenRequestStep {
        func describe() -> String
        func adjust(_ item: SpecimenRequest, value: Double) -> Double
    }

    final class CapSpecimenRequestAdjuster: SpecimenRequestStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SpecimenRequest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentSpecimenRequestAdjuster: SpecimenRequestStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SpecimenRequest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingSpecimenRequestAdjuster: SpecimenRequestStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SpecimenRequest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedSpecimenRequestAdjuster: SpecimenRequestStep {
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

        func adjust(_ item: SpecimenRequest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SpecimenRequestBatchSizeOffsetAdjuster: SpecimenRequestStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: SpecimenRequest, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    final class TieredSpecimenRequestAdjuster: SpecimenRequestStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SpecimenRequest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the specimen request steps in order and keeps a trace of each.
    final class SpecimenRequestEngine {
        var steps: [any SpecimenRequestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SpecimenRequestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: SpecimenRequest) -> Double {
            var current = item.projectedVolume()
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

        func evaluateAll(_ items: [SpecimenRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultSpecimenRequestEngine(_ flags: Kit.Flags.Registry) -> SpecimenRequestEngine {
        return SpecimenRequestEngine(
            steps: [
                CapSpecimenRequestAdjuster(cap: 38641.0),
                PercentSpecimenRequestAdjuster(percent: -24.0),
                RoundingSpecimenRequestAdjuster(step: 5.0),
                FlaggedSpecimenRequestAdjuster(flags: flags, flag: "specimen-request-tiered", percent: 7.9),
                SpecimenRequestBatchSizeOffsetAdjuster(weight: 1.1),
                TieredSpecimenRequestAdjuster(
                    bounds: [1696.0, 3283.0, 4320.0, 4494.0],
                    rates: [1.11, 1.09, 1.17, 0.82]
                ),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 61475.5
        )
    }
}
