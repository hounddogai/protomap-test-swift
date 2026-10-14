import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the rounding record calculation.
    protocol RoundingRecordAdjuster {
        func describe() -> String
        func adjust(_ item: RoundingRecord, value: Double) -> Double
    }

    final class UnitRoundingRecordAdjuster: RoundingRecordAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: RoundingRecord, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingRecordVisitMinutesOffsetAdjuster: RoundingRecordAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus visit minutes times \(weight)"
        }

        func adjust(_ item: RoundingRecord, value: Double) -> Double {
            return value + Double(item.visitMinutes) * weight
        }
    }

    final class CapRoundingRecordAdjuster: RoundingRecordAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RoundingRecord, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedRoundingRecordAdjuster: RoundingRecordAdjuster {
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

        func adjust(_ item: RoundingRecord, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredRoundingRecordAdjuster: RoundingRecordAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RoundingRecord, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the rounding record steps in order and keeps a trace of each.
    final class RoundingRecordEngine {
        var steps: [any RoundingRecordAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RoundingRecordAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RoundingRecord) -> Double {
            var current = item.weightedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any RoundingRecordAdjuster = steps[index]
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

        func evaluateAll(_ items: [RoundingRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRoundingRecordEngine(_ flags: Kit.Flags.Registry) -> RoundingRecordEngine {
        return RoundingRecordEngine(
            steps: [
                UnitRoundingRecordAdjuster(factors: ["south": 1.37]),
                RoundingRecordVisitMinutesOffsetAdjuster(weight: 1.11),
                CapRoundingRecordAdjuster(cap: 15034.0),
                FlaggedRoundingRecordAdjuster(flags: flags, flag: "rounding-record-strict", percent: 4.1),
                TieredRoundingRecordAdjuster(bounds: [318.0, 5311.0, 6619.0, 9317.0], rates: [0.94, 1.2, 1.01, 1.13]),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 13495.7
        )
    }
}
