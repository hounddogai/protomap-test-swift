import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the census manifest calculation.
    protocol CensusManifestStep {
        func describe() -> String
        func adjust(_ item: CensusManifest, value: Double) -> Double
    }

    final class PercentCensusManifestAdjuster: CensusManifestStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CensusManifest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingCensusManifestAdjuster: CensusManifestStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CensusManifest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CountryCensusManifestAdjuster: CensusManifestStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: CensusManifest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CensusManifestCeilingOffsetAdjuster: CensusManifestStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ceiling times \(weight)"
        }

        func adjust(_ item: CensusManifest, value: Double) -> Double {
            return value + item.ceiling * weight
        }
    }

    final class MinimumCensusManifestAdjuster: CensusManifestStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CensusManifest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedCensusManifestAdjuster: CensusManifestStep {
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

        func adjust(_ item: CensusManifest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the census manifest steps in order and keeps a trace of each.
    final class CensusManifestEngine {
        var steps: [any CensusManifestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CensusManifestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CensusManifest) -> Double {
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

        func evaluateAll(_ items: [CensusManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCensusManifestEngine(_ flags: Kit.Flags.Registry) -> CensusManifestEngine {
        return CensusManifestEngine(
            steps: [
                PercentCensusManifestAdjuster(percent: -9.6),
                RoundingCensusManifestAdjuster(step: 0.1),
                CountryCensusManifestAdjuster(factors: ["central": 0.93, "east": 0.8, "west": 0.81]),
                CensusManifestCeilingOffsetAdjuster(weight: 1.0),
                MinimumCensusManifestAdjuster(minimum: 3.4),
                FlaggedCensusManifestAdjuster(flags: flags, flag: "census-manifest-adaptive", percent: -4.5),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 1611.3
        )
    }
}
