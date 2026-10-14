import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the lenient program profile calculation.
    protocol LenientProgramProfileAdjuster {
        func describe() -> String
        func adjust(_ item: LenientProgramProfile, value: Double) -> Double
    }

    final class CapLenientProgramProfileAdjuster: LenientProgramProfileAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientProgramProfile, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TitleLenientProgramProfileAdjuster: LenientProgramProfileAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: LenientProgramProfile, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class LenientProgramProfileAcuityOffsetAdjuster: LenientProgramProfileAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus acuity times \(weight)"
        }

        func adjust(_ item: LenientProgramProfile, value: Double) -> Double {
            return value + Double(item.acuity) * weight
        }
    }

    final class RoundingLenientProgramProfileAdjuster: LenientProgramProfileAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientProgramProfile, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredLenientProgramProfileAdjuster: LenientProgramProfileAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientProgramProfile, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the lenient program profile steps in order and keeps a trace of each.
    final class LenientProgramProfileEngine {
        var steps: [any LenientProgramProfileAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientProgramProfileAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LenientProgramProfile) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientProgramProfileAdjuster = steps[index]
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

        func evaluateAll(_ items: [LenientProgramProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLenientProgramProfileEngine() -> LenientProgramProfileEngine {
        return LenientProgramProfileEngine(
            steps: [
                CapLenientProgramProfileAdjuster(cap: 40815.0),
                TitleLenientProgramProfileAdjuster(factors: ["west": 0.72, "retail": 1.02, "online": 0.99]),
                LenientProgramProfileAcuityOffsetAdjuster(weight: 1.26),
                RoundingLenientProgramProfileAdjuster(step: 0.5),
                TieredLenientProgramProfileAdjuster(bounds: [3315.0, 3785.0, 4439.0], rates: [1.15, 0.82, 1.17]),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 63926.2
        )
    }
}
