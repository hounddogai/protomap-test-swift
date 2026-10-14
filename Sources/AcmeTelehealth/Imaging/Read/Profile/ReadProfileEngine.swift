import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the read profile calculation.
    protocol ReadProfileAdjuster {
        func describe() -> String
        func adjust(_ item: ReadProfile, value: Double) -> Double
    }

    final class RegionReadProfileAdjuster: ReadProfileAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: ReadProfile, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class ReadProfileAcuityOffsetAdjuster: ReadProfileAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus acuity times \(weight)"
        }

        func adjust(_ item: ReadProfile, value: Double) -> Double {
            return value + Double(item.acuity) * weight
        }
    }

    final class RoundingReadProfileAdjuster: ReadProfileAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ReadProfile, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the read profile steps in order and keeps a trace of each.
    final class ReadProfileEngine {
        var steps: [any ReadProfileAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReadProfileAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ReadProfile) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ReadProfileAdjuster = steps[index]
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

        func evaluateAll(_ items: [ReadProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultReadProfileEngine() -> ReadProfileEngine {
        return ReadProfileEngine(
            steps: [
                RegionReadProfileAdjuster(factors: ["online": 1.08, "west": 1.36]),
                ReadProfileAcuityOffsetAdjuster(weight: 0.75),
                RoundingReadProfileAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 64245.9
        )
    }
}
