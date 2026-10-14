import AcmePlatform
import Foundation

extension Labs {
    /// One step of the fallback reference range batch calculation.
    protocol FallbackReferenceRangeBatchAdjuster {
        func describe() -> String
        func adjust(_ item: FallbackReferenceRangeBatch, value: Double) -> Double
    }

    final class FlaggedFallbackReferenceRangeBatchAdjuster: FallbackReferenceRangeBatchAdjuster {
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

        func adjust(_ item: FallbackReferenceRangeBatch, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleFallbackReferenceRangeBatchAdjuster: FallbackReferenceRangeBatchAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: FallbackReferenceRangeBatch, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumFallbackReferenceRangeBatchAdjuster: FallbackReferenceRangeBatchAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackReferenceRangeBatch, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the fallback reference range batch steps in order and keeps a trace of each.
    final class FallbackReferenceRangeBatchEngine {
        var steps: [any FallbackReferenceRangeBatchAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackReferenceRangeBatchAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: FallbackReferenceRangeBatch) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackReferenceRangeBatchAdjuster = steps[index]
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

        func evaluateAll(_ items: [FallbackReferenceRangeBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultFallbackReferenceRangeBatchEngine(_ flags: Kit.Flags.Registry) -> FallbackReferenceRangeBatchEngine {
        return FallbackReferenceRangeBatchEngine(
            steps: [
                FlaggedFallbackReferenceRangeBatchAdjuster(
                    flags: flags,
                    flag: "fallback-reference-range-batch-legacy",
                    percent: 8.0
                ),
                TitleFallbackReferenceRangeBatchAdjuster(factors: ["north": 1.08]),
                MinimumFallbackReferenceRangeBatchAdjuster(minimum: 38.5),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 32885.9
        )
    }
}
