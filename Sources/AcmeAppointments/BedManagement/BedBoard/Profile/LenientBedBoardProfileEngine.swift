import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the lenient bed board profile calculation.
    protocol LenientBedBoardProfileFactor {
        func describe() -> String
        func adjust(_ item: LenientBedBoardProfile, value: Double) -> Double
    }

    final class MinimumLenientBedBoardProfileAdjuster: LenientBedBoardProfileFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientBedBoardProfile, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredLenientBedBoardProfileAdjuster: LenientBedBoardProfileFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientBedBoardProfile, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingLenientBedBoardProfileAdjuster: LenientBedBoardProfileFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientBedBoardProfile, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentLenientBedBoardProfileAdjuster: LenientBedBoardProfileFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientBedBoardProfile, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the lenient bed board profile steps in order and keeps a trace of each.
    final class LenientBedBoardProfileEngine {
        var steps: [any LenientBedBoardProfileFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientBedBoardProfileFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LenientBedBoardProfile) -> Double {
            var current = item.effectiveTotal()
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

        func evaluateAll(_ items: [LenientBedBoardProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLenientBedBoardProfileEngine() -> LenientBedBoardProfileEngine {
        return LenientBedBoardProfileEngine(
            steps: [
                MinimumLenientBedBoardProfileAdjuster(minimum: 2.2),
                TieredLenientBedBoardProfileAdjuster(bounds: [3893.0, 9214.0], rates: [1.06, 0.99]),
                RoundingLenientBedBoardProfileAdjuster(step: 0.5),
                PercentLenientBedBoardProfileAdjuster(percent: 22.1),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 77037.1
        )
    }
}
