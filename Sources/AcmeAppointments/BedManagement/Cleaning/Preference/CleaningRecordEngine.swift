import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the cleaning record calculation.
    protocol CleaningRecordFactor {
        func describe() -> String
        func adjust(_ item: CleaningRecord, value: Double) -> Double
    }

    final class FlaggedCleaningRecordAdjuster: CleaningRecordFactor {
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

        func adjust(_ item: CleaningRecord, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumCleaningRecordAdjuster: CleaningRecordFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CleaningRecord, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapCleaningRecordAdjuster: CleaningRecordFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CleaningRecord, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredCleaningRecordAdjuster: CleaningRecordFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CleaningRecord, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CleaningRecordRatioOffsetAdjuster: CleaningRecordFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: CleaningRecord, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    /// Runs the cleaning record steps in order and keeps a trace of each.
    final class CleaningRecordEngine {
        var steps: [any CleaningRecordFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CleaningRecordFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CleaningRecord) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any CleaningRecordFactor = steps[index]
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

        func evaluateAll(_ items: [CleaningRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCleaningRecordEngine(_ flags: Kit.Flags.Registry) -> CleaningRecordEngine {
        return CleaningRecordEngine(
            steps: [
                FlaggedCleaningRecordAdjuster(flags: flags, flag: "cleaning-record-regional", percent: -7.8),
                MinimumCleaningRecordAdjuster(minimum: 39.2),
                CapCleaningRecordAdjuster(cap: 28343.0),
                TieredCleaningRecordAdjuster(bounds: [1355.0, 2925.0], rates: [0.89, 1.04]),
                CleaningRecordRatioOffsetAdjuster(weight: 1.39),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 30948.6
        )
    }
}
