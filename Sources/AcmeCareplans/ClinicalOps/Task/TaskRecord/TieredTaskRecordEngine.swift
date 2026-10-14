import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the tiered task record calculation.
    protocol TieredTaskRecordAdjuster {
        func describe() -> String
        func adjust(_ item: TieredTaskRecord, value: Double) -> Double
    }

    final class TieredTaskRecordBudgetOffsetAdjuster: TieredTaskRecordAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus budget times \(weight)"
        }

        func adjust(_ item: TieredTaskRecord, value: Double) -> Double {
            return value + item.budget * weight
        }
    }

    final class CapTieredTaskRecordAdjuster: TieredTaskRecordAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredTaskRecord, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentTieredTaskRecordAdjuster: TieredTaskRecordAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredTaskRecord, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredTieredTaskRecordAdjuster: TieredTaskRecordAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredTaskRecord, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the tiered task record steps in order and keeps a trace of each.
    final class TieredTaskRecordEngine {
        var steps: [any TieredTaskRecordAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredTaskRecordAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: TieredTaskRecord) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any TieredTaskRecordAdjuster = steps[index]
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

        func evaluateAll(_ items: [TieredTaskRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultTieredTaskRecordEngine() -> TieredTaskRecordEngine {
        return TieredTaskRecordEngine(
            steps: [
                TieredTaskRecordBudgetOffsetAdjuster(weight: 1.62),
                CapTieredTaskRecordAdjuster(cap: 20287.0),
                PercentTieredTaskRecordAdjuster(percent: 11.3),
                TieredTieredTaskRecordAdjuster(
                    bounds: [928.0, 1795.0, 5640.0, 5966.0],
                    rates: [1.05, 1.11, 0.93, 0.82]
                ),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 1308.8
        )
    }
}
