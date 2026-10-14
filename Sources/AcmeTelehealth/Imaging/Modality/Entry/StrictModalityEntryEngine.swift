import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the strict modality entry calculation.
    protocol StrictModalityEntryFactor {
        func describe() -> String
        func adjust(_ item: StrictModalityEntry, value: Double) -> Double
    }

    final class TieredStrictModalityEntryAdjuster: StrictModalityEntryFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictModalityEntry, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedStrictModalityEntryAdjuster: StrictModalityEntryFactor {
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

        func adjust(_ item: StrictModalityEntry, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class UnitStrictModalityEntryAdjuster: StrictModalityEntryFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: StrictModalityEntry, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumStrictModalityEntryAdjuster: StrictModalityEntryFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictModalityEntry, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the strict modality entry steps in order and keeps a trace of each.
    final class StrictModalityEntryEngine {
        var steps: [any StrictModalityEntryFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictModalityEntryFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: StrictModalityEntry) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any StrictModalityEntryFactor = steps[index]
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

        func evaluateAll(_ items: [StrictModalityEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultStrictModalityEntryEngine(_ flags: Kit.Flags.Registry) -> StrictModalityEntryEngine {
        return StrictModalityEntryEngine(
            steps: [
                TieredStrictModalityEntryAdjuster(bounds: [6138.0, 6753.0, 8434.0], rates: [0.9, 0.82, 1.04]),
                FlaggedStrictModalityEntryAdjuster(
                    flags: flags,
                    flag: "strict-modality-entry-seasonal",
                    percent: -2.9
                ),
                UnitStrictModalityEntryAdjuster(factors: ["west": 1.14, "east": 1.22]),
                MinimumStrictModalityEntryAdjuster(minimum: 37.3),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 58858.3
        )
    }
}
