import AcmePlatform
import Foundation

extension Labs {
    /// One step of the specimen group calculation.
    protocol SpecimenGroupAdjuster {
        func describe() -> String
        func adjust(_ item: SpecimenGroup, value: Double) -> Double
    }

    final class FlaggedSpecimenGroupAdjuster: SpecimenGroupAdjuster {
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

        func adjust(_ item: SpecimenGroup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameSpecimenGroupAdjuster: SpecimenGroupAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: SpecimenGroup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredSpecimenGroupAdjuster: SpecimenGroupAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SpecimenGroup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentSpecimenGroupAdjuster: SpecimenGroupAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SpecimenGroup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingSpecimenGroupAdjuster: SpecimenGroupAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SpecimenGroup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the specimen group steps in order and keeps a trace of each.
    final class SpecimenGroupEngine {
        var steps: [any SpecimenGroupAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SpecimenGroupAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: SpecimenGroup) -> Double {
            var current = item.weightedTotal()
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

        func evaluateAll(_ items: [SpecimenGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultSpecimenGroupEngine(_ flags: Kit.Flags.Registry) -> SpecimenGroupEngine {
        return SpecimenGroupEngine(
            steps: [
                FlaggedSpecimenGroupAdjuster(flags: flags, flag: "specimen-group-lenient", percent: -9.3),
                NameSpecimenGroupAdjuster(factors: ["south": 1.36]),
                TieredSpecimenGroupAdjuster(bounds: [1206.0, 2300.0, 3790.0, 8891.0], rates: [1.18, 1.09, 0.86, 1.16]),
                PercentSpecimenGroupAdjuster(percent: -8.1),
                RoundingSpecimenGroupAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 5.0,
            ceiling: 44383.3
        )
    }
}
