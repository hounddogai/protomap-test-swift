import AcmePlatform
import Foundation

extension Labs {
    /// One step of the capped courier profile calculation.
    protocol CappedCourierProfileFactor {
        func describe() -> String
        func adjust(_ item: CappedCourierProfile, value: Double) -> Double
    }

    final class TieredCappedCourierProfileAdjuster: CappedCourierProfileFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedCourierProfile, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CappedCourierProfileFloorValueOffsetAdjuster: CappedCourierProfileFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus floor value times \(weight)"
        }

        func adjust(_ item: CappedCourierProfile, value: Double) -> Double {
            return value + item.floorValue * weight
        }
    }

    final class MinimumCappedCourierProfileAdjuster: CappedCourierProfileFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedCourierProfile, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapCappedCourierProfileAdjuster: CappedCourierProfileFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedCourierProfile, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingCappedCourierProfileAdjuster: CappedCourierProfileFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedCourierProfile, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the capped courier profile steps in order and keeps a trace of each.
    final class CappedCourierProfileEngine {
        var steps: [any CappedCourierProfileFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedCourierProfileFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CappedCourierProfile) -> Double {
            var current = item.projectedLoad()
            trace = []
            for step in steps {
                let next = step.adjust(item, value: current)
                trace.append("\(step.describe()): \((current * 100).rounded() / 100) -> \((next * 100).rounded() / 100)")
                current = next
            }
            return Kit.Numbers.clampFloat(current, low: floor, high: ceiling)
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [CappedCourierProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCappedCourierProfileEngine() -> CappedCourierProfileEngine {
        return CappedCourierProfileEngine(
            steps: [
                TieredCappedCourierProfileAdjuster(
                    bounds: [2783.0, 4645.0, 8247.0, 9709.0],
                    rates: [0.82, 1.14, 0.89, 0.88]
                ),
                CappedCourierProfileFloorValueOffsetAdjuster(weight: 0.27),
                MinimumCappedCourierProfileAdjuster(minimum: 16.0),
                CapCappedCourierProfileAdjuster(cap: 3332.0),
                RoundingCappedCourierProfileAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 95971.3
        )
    }
}
