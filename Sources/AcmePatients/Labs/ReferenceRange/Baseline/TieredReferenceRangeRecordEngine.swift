import AcmePlatform
import Foundation

extension Labs {
    /// One step of the tiered reference range record calculation.
    protocol BaselineTieredReferenceRangeRecordAdjuster {
        func describe() -> String
        func adjust(_ item: TieredReferenceRangeRecord, value: Double) -> Double
    }

    final class RoundingTieredReferenceRangeRecordAdjuster: BaselineTieredReferenceRangeRecordAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredReferenceRangeRecord, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapTieredReferenceRangeRecordAdjuster: BaselineTieredReferenceRangeRecordAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredReferenceRangeRecord, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredTieredReferenceRangeRecordAdjuster: BaselineTieredReferenceRangeRecordAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredReferenceRangeRecord, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumTieredReferenceRangeRecordAdjuster: BaselineTieredReferenceRangeRecordAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredReferenceRangeRecord, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the tiered reference range record steps in order and keeps a trace of each.
    final class TieredReferenceRangeRecordEngine {
        var steps: [any BaselineTieredReferenceRangeRecordAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BaselineTieredReferenceRangeRecordAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: TieredReferenceRangeRecord) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any BaselineTieredReferenceRangeRecordAdjuster = steps[index]
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

        func evaluateAll(_ items: [TieredReferenceRangeRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultTieredReferenceRangeRecordEngine() -> TieredReferenceRangeRecordEngine {
        return TieredReferenceRangeRecordEngine(
            steps: [
                RoundingTieredReferenceRangeRecordAdjuster(step: 5.0),
                CapTieredReferenceRangeRecordAdjuster(cap: 38868.0),
                TieredTieredReferenceRangeRecordAdjuster(bounds: [830.0, 5215.0], rates: [0.94, 1.14]),
                MinimumTieredReferenceRangeRecordAdjuster(minimum: 1.7),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 14319.8
        )
    }
}
