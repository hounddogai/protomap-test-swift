import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the program exception calculation.
    protocol ProgramExceptionAdjuster {
        func describe() -> String
        func adjust(_ item: ProgramException, value: Double) -> Double
    }

    final class RoundingProgramExceptionAdjuster: ProgramExceptionAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ProgramException, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapProgramExceptionAdjuster: ProgramExceptionAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ProgramException, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class ProgramExceptionDurationMinutesOffsetAdjuster: ProgramExceptionAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus duration minutes times \(weight)"
        }

        func adjust(_ item: ProgramException, value: Double) -> Double {
            return value + Double(item.durationMinutes) * weight
        }
    }

    final class TieredProgramExceptionAdjuster: ProgramExceptionAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ProgramException, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentProgramExceptionAdjuster: ProgramExceptionAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ProgramException, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the program exception steps in order and keeps a trace of each.
    final class ProgramExceptionEngine {
        var steps: [any ProgramExceptionAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ProgramExceptionAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ProgramException) -> Double {
            var current = item.weightedExposure()
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

        func evaluateAll(_ items: [ProgramException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultProgramExceptionEngine() -> ProgramExceptionEngine {
        return ProgramExceptionEngine(
            steps: [
                RoundingProgramExceptionAdjuster(step: 5.0),
                CapProgramExceptionAdjuster(cap: 1798.0),
                ProgramExceptionDurationMinutesOffsetAdjuster(weight: 1.76),
                TieredProgramExceptionAdjuster(bounds: [432.0, 595.0], rates: [0.9, 1.14]),
                PercentProgramExceptionAdjuster(percent: 16.2),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 43975.5
        )
    }
}
