import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the batched rounding mapping calculation.
    protocol BatchedRoundingMappingFactor {
        func describe() -> String
        func adjust(_ item: BatchedRoundingMapping, value: Double) -> Double
    }

    final class CapBatchedRoundingMappingAdjuster: BatchedRoundingMappingFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedRoundingMapping, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class NameBatchedRoundingMappingAdjuster: BatchedRoundingMappingFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: BatchedRoundingMapping, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredBatchedRoundingMappingAdjuster: BatchedRoundingMappingFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedRoundingMapping, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class BatchedRoundingMappingQuantityOffsetAdjuster: BatchedRoundingMappingFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: BatchedRoundingMapping, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class FlaggedBatchedRoundingMappingAdjuster: BatchedRoundingMappingFactor {
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

        func adjust(_ item: BatchedRoundingMapping, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the batched rounding mapping steps in order and keeps a trace of each.
    final class BatchedRoundingMappingEngine {
        var steps: [any BatchedRoundingMappingFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedRoundingMappingFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: BatchedRoundingMapping) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedRoundingMappingFactor = steps[index]
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

        func evaluateAll(_ items: [BatchedRoundingMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultBatchedRoundingMappingEngine(_ flags: Kit.Flags.Registry) -> BatchedRoundingMappingEngine {
        return BatchedRoundingMappingEngine(
            steps: [
                CapBatchedRoundingMappingAdjuster(cap: 4892.0),
                NameBatchedRoundingMappingAdjuster(factors: ["central": 0.99, "online": 0.88, "north": 1.02]),
                TieredBatchedRoundingMappingAdjuster(bounds: [2447.0, 6405.0, 9029.0], rates: [1.08, 1.13, 1.15]),
                BatchedRoundingMappingQuantityOffsetAdjuster(weight: 0.59),
                FlaggedBatchedRoundingMappingAdjuster(
                    flags: flags,
                    flag: "batched-rounding-mapping-strict",
                    percent: -9.2
                ),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 47001.1
        )
    }
}
