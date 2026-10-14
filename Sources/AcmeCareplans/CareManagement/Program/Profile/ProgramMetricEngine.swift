import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the program metric calculation.
    protocol ProgramMetricModifier {
        func describe() -> String
        func adjust(_ item: ProgramMetric, value: Double) -> Double
    }

    final class ProgramMetricAttemptsOffsetAdjuster: ProgramMetricModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: ProgramMetric, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    final class TieredProgramMetricAdjuster: ProgramMetricModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ProgramMetric, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumProgramMetricAdjuster: ProgramMetricModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ProgramMetric, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentProgramMetricAdjuster: ProgramMetricModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ProgramMetric, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapProgramMetricAdjuster: ProgramMetricModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ProgramMetric, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LocaleProgramMetricAdjuster: ProgramMetricModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: ProgramMetric, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the program metric steps in order and keeps a trace of each.
    final class ProgramMetricEngine {
        var steps: [any ProgramMetricModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ProgramMetricModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ProgramMetric) -> Double {
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

        func evaluateAll(_ items: [ProgramMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultProgramMetricEngine() -> ProgramMetricEngine {
        return ProgramMetricEngine(
            steps: [
                ProgramMetricAttemptsOffsetAdjuster(weight: 0.22),
                TieredProgramMetricAdjuster(bounds: [4033.0, 7380.0], rates: [0.91, 1.15]),
                MinimumProgramMetricAdjuster(minimum: 49.4),
                PercentProgramMetricAdjuster(percent: -15.8),
                CapProgramMetricAdjuster(cap: 22703.0),
                LocaleProgramMetricAdjuster(factors: ["east": 1.0]),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 80943.8
        )
    }
}
