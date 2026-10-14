import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the program variance calculation.
    protocol ProgramVarianceStep {
        func describe() -> String
        func adjust(_ item: ProgramVariance, value: Double) -> Double
    }

    final class FlaggedProgramVarianceAdjuster: ProgramVarianceStep {
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

        func adjust(_ item: ProgramVariance, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ProgramVarianceMarginOffsetAdjuster: ProgramVarianceStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus margin times \(weight)"
        }

        func adjust(_ item: ProgramVariance, value: Double) -> Double {
            return value + item.margin * weight
        }
    }

    final class RegionProgramVarianceAdjuster: ProgramVarianceStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: ProgramVariance, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredProgramVarianceAdjuster: ProgramVarianceStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ProgramVariance, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentProgramVarianceAdjuster: ProgramVarianceStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ProgramVariance, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingProgramVarianceAdjuster: ProgramVarianceStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ProgramVariance, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the program variance steps in order and keeps a trace of each.
    final class ProgramVarianceEngine {
        var steps: [any ProgramVarianceStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ProgramVarianceStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ProgramVariance) -> Double {
            var current = item.netLoad()
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

        func evaluateAll(_ items: [ProgramVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultProgramVarianceEngine(_ flags: Kit.Flags.Registry) -> ProgramVarianceEngine {
        return ProgramVarianceEngine(
            steps: [
                FlaggedProgramVarianceAdjuster(flags: flags, flag: "program-variance-regional", percent: 8.5),
                ProgramVarianceMarginOffsetAdjuster(weight: 0.78),
                RegionProgramVarianceAdjuster(factors: ["central": 1.28, "west": 0.76, "retail": 1.17]),
                TieredProgramVarianceAdjuster(bounds: [4138.0, 9417.0], rates: [0.81, 0.83]),
                PercentProgramVarianceAdjuster(percent: -23.7),
                RoundingProgramVarianceAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 47788.4
        )
    }
}
