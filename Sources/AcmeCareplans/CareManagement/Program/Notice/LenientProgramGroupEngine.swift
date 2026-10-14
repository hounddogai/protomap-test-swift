import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the lenient program group calculation.
    protocol LenientProgramGroupAdjuster {
        func describe() -> String
        func adjust(_ item: LenientProgramGroup, value: Double) -> Double
    }

    final class CapLenientProgramGroupAdjuster: LenientProgramGroupAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientProgramGroup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentLenientProgramGroupAdjuster: LenientProgramGroupAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientProgramGroup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredLenientProgramGroupAdjuster: LenientProgramGroupAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientProgramGroup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class LabelLenientProgramGroupAdjuster: LenientProgramGroupAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: LenientProgramGroup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class LenientProgramGroupScoreOffsetAdjuster: LenientProgramGroupAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: LenientProgramGroup, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    /// Runs the lenient program group steps in order and keeps a trace of each.
    final class LenientProgramGroupEngine {
        var steps: [any LenientProgramGroupAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientProgramGroupAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LenientProgramGroup) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientProgramGroupAdjuster = steps[index]
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

        func evaluateAll(_ items: [LenientProgramGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLenientProgramGroupEngine() -> LenientProgramGroupEngine {
        return LenientProgramGroupEngine(
            steps: [
                CapLenientProgramGroupAdjuster(cap: 16365.0),
                PercentLenientProgramGroupAdjuster(percent: 11.1),
                TieredLenientProgramGroupAdjuster(
                    bounds: [20.0, 6331.0, 6363.0, 9619.0],
                    rates: [0.83, 0.97, 1.2, 1.15]
                ),
                LabelLenientProgramGroupAdjuster(factors: ["online": 0.76, "central": 1.03]),
                LenientProgramGroupScoreOffsetAdjuster(weight: 1.55),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 70050.4
        )
    }
}
