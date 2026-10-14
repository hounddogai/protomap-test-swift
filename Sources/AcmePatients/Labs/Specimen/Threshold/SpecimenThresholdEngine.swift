import AcmePlatform
import Foundation

extension Labs {
    /// One step of the specimen threshold calculation.
    protocol SpecimenThresholdAdjuster {
        func describe() -> String
        func adjust(_ item: SpecimenThreshold, value: Double) -> Double
    }

    final class TieredSpecimenThresholdAdjuster: SpecimenThresholdAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SpecimenThreshold, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedSpecimenThresholdAdjuster: SpecimenThresholdAdjuster {
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

        func adjust(_ item: SpecimenThreshold, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleSpecimenThresholdAdjuster: SpecimenThresholdAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: SpecimenThreshold, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the specimen threshold steps in order and keeps a trace of each.
    final class SpecimenThresholdEngine {
        var steps: [any SpecimenThresholdAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SpecimenThresholdAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: SpecimenThreshold) -> Double {
            var current = item.adjustedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any SpecimenThresholdAdjuster = steps[index]
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

        func evaluateAll(_ items: [SpecimenThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultSpecimenThresholdEngine(_ flags: Kit.Flags.Registry) -> SpecimenThresholdEngine {
        return SpecimenThresholdEngine(
            steps: [
                TieredSpecimenThresholdAdjuster(
                    bounds: [284.0, 1153.0, 4294.0, 5841.0],
                    rates: [0.98, 1.09, 0.84, 1.19]
                ),
                FlaggedSpecimenThresholdAdjuster(flags: flags, flag: "specimen-threshold-batched", percent: -6.2),
                TitleSpecimenThresholdAdjuster(factors: ["west": 1.11, "north": 1.33, "central": 0.9]),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 79686.0
        )
    }
}
