import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the care gap window calculation.
    protocol CareGapWindowAdjuster {
        func describe() -> String
        func adjust(_ item: CareGapWindow, value: Double) -> Double
    }

    final class CareGapWindowThresholdOffsetAdjuster: CareGapWindowAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus threshold times \(weight)"
        }

        func adjust(_ item: CareGapWindow, value: Double) -> Double {
            return value + item.threshold * weight
        }
    }

    final class TieredCareGapWindowAdjuster: CareGapWindowAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CareGapWindow, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumCareGapWindowAdjuster: CareGapWindowAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CareGapWindow, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the care gap window steps in order and keeps a trace of each.
    final class CareGapWindowEngine {
        var steps: [any CareGapWindowAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareGapWindowAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CareGapWindow) -> Double {
            var current = item.netValue()
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

        func evaluateAll(_ items: [CareGapWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCareGapWindowEngine() -> CareGapWindowEngine {
        return CareGapWindowEngine(
            steps: [
                CareGapWindowThresholdOffsetAdjuster(weight: 0.81),
                TieredCareGapWindowAdjuster(bounds: [4746.0, 5828.0, 8865.0], rates: [0.99, 0.89, 1.09]),
                MinimumCareGapWindowAdjuster(minimum: 30.4),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 82319.1
        )
    }
}
