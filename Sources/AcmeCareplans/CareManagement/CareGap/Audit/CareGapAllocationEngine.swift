import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the care gap allocation calculation.
    protocol CareGapAllocationFactor {
        func describe() -> String
        func adjust(_ item: CareGapAllocation, value: Double) -> Double
    }

    final class WardCareGapAllocationAdjuster: CareGapAllocationFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: CareGapAllocation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredCareGapAllocationAdjuster: CareGapAllocationFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CareGapAllocation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapCareGapAllocationAdjuster: CareGapAllocationFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CareGapAllocation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingCareGapAllocationAdjuster: CareGapAllocationFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CareGapAllocation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CareGapAllocationQuantityOffsetAdjuster: CareGapAllocationFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: CareGapAllocation, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    /// Runs the care gap allocation steps in order and keeps a trace of each.
    final class CareGapAllocationEngine {
        var steps: [any CareGapAllocationFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareGapAllocationFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CareGapAllocation) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any CareGapAllocationFactor = steps[index]
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

        func evaluateAll(_ items: [CareGapAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCareGapAllocationEngine() -> CareGapAllocationEngine {
        return CareGapAllocationEngine(
            steps: [
                WardCareGapAllocationAdjuster(factors: ["south": 0.88, "east": 1.09]),
                TieredCareGapAllocationAdjuster(
                    bounds: [265.0, 1366.0, 5257.0, 8127.0],
                    rates: [0.9, 1.15, 1.17, 0.82]
                ),
                CapCareGapAllocationAdjuster(cap: 45781.0),
                RoundingCareGapAllocationAdjuster(step: 0.1),
                CareGapAllocationQuantityOffsetAdjuster(weight: 1.63),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 60424.1
        )
    }
}
