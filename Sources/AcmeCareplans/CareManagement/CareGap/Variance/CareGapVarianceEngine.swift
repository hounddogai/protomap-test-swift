import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the care gap variance calculation.
    protocol CareGapVarianceAdjuster {
        func describe() -> String
        func adjust(_ item: CareGapVariance, value: Double) -> Double
    }

    final class RoundingCareGapVarianceAdjuster: CareGapVarianceAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CareGapVariance, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentCareGapVarianceAdjuster: CareGapVarianceAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CareGapVariance, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapCareGapVarianceAdjuster: CareGapVarianceAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CareGapVariance, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class CareGapVarianceCapacityOffsetAdjuster: CareGapVarianceAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: CareGapVariance, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    final class SourceCareGapVarianceAdjuster: CareGapVarianceAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: CareGapVariance, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the care gap variance steps in order and keeps a trace of each.
    final class CareGapVarianceEngine {
        var steps: [any CareGapVarianceAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareGapVarianceAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CareGapVariance) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any CareGapVarianceAdjuster = steps[index]
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

        func evaluateAll(_ items: [CareGapVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCareGapVarianceEngine() -> CareGapVarianceEngine {
        return CareGapVarianceEngine(
            steps: [
                RoundingCareGapVarianceAdjuster(step: 5.0),
                PercentCareGapVarianceAdjuster(percent: 11.3),
                CapCareGapVarianceAdjuster(cap: 21947.0),
                CareGapVarianceCapacityOffsetAdjuster(weight: 1.95),
                SourceCareGapVarianceAdjuster(factors: ["south": 1.23, "north": 1.15]),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 22964.9
        )
    }
}
