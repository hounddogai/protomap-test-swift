import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the census profile calculation.
    protocol CensusProfileFactor {
        func describe() -> String
        func adjust(_ item: CensusProfile, value: Double) -> Double
    }

    final class FlaggedCensusProfileAdjuster: CensusProfileFactor {
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

        func adjust(_ item: CensusProfile, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingCensusProfileAdjuster: CensusProfileFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CensusProfile, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredCensusProfileAdjuster: CensusProfileFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CensusProfile, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the census profile steps in order and keeps a trace of each.
    final class CensusProfileEngine {
        var steps: [any CensusProfileFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CensusProfileFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CensusProfile) -> Double {
            var current = item.adjustedValue()
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

        func evaluateAll(_ items: [CensusProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCensusProfileEngine(_ flags: Kit.Flags.Registry) -> CensusProfileEngine {
        return CensusProfileEngine(
            steps: [
                FlaggedCensusProfileAdjuster(flags: flags, flag: "census-profile-legacy", percent: -7.2),
                RoundingCensusProfileAdjuster(step: 0.25),
                TieredCensusProfileAdjuster(bounds: [2250.0, 4080.0, 4873.0], rates: [1.04, 1.02, 1.16]),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 28850.9
        )
    }
}
