import AcmePlatform
import Foundation

extension Labs {
    /// One step of the specimen variance calculation.
    protocol SpecimenVarianceAdjuster {
        func describe() -> String
        func adjust(_ item: SpecimenVariance, value: Double) -> Double
    }

    final class FlaggedSpecimenVarianceAdjuster: SpecimenVarianceAdjuster {
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

        func adjust(_ item: SpecimenVariance, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredSpecimenVarianceAdjuster: SpecimenVarianceAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SpecimenVariance, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumSpecimenVarianceAdjuster: SpecimenVarianceAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SpecimenVariance, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the specimen variance steps in order and keeps a trace of each.
    final class SpecimenVarianceEngine {
        var steps: [any SpecimenVarianceAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SpecimenVarianceAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: SpecimenVariance) -> Double {
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

        func evaluateAll(_ items: [SpecimenVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultSpecimenVarianceEngine(_ flags: Kit.Flags.Registry) -> SpecimenVarianceEngine {
        return SpecimenVarianceEngine(
            steps: [
                FlaggedSpecimenVarianceAdjuster(flags: flags, flag: "specimen-variance-capped", percent: 9.8),
                TieredSpecimenVarianceAdjuster(bounds: [5911.0, 6290.0, 9859.0], rates: [0.89, 0.89, 1.19]),
                MinimumSpecimenVarianceAdjuster(minimum: 17.9),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 90316.1
        )
    }
}
