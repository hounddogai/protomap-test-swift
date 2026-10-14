import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the legacy task mapping calculation.
    protocol LegacyTaskMappingStep {
        func describe() -> String
        func adjust(_ item: LegacyTaskMapping, value: Double) -> Double
    }

    final class PercentLegacyTaskMappingAdjuster: LegacyTaskMappingStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LegacyTaskMapping, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredLegacyTaskMappingAdjuster: LegacyTaskMappingStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyTaskMapping, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class WardLegacyTaskMappingAdjuster: LegacyTaskMappingStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: LegacyTaskMapping, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapLegacyTaskMappingAdjuster: LegacyTaskMappingStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacyTaskMapping, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the legacy task mapping steps in order and keeps a trace of each.
    final class LegacyTaskMappingEngine {
        var steps: [any LegacyTaskMappingStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyTaskMappingStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LegacyTaskMapping) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacyTaskMappingStep = steps[index]
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

        func evaluateAll(_ items: [LegacyTaskMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLegacyTaskMappingEngine() -> LegacyTaskMappingEngine {
        return LegacyTaskMappingEngine(
            steps: [
                PercentLegacyTaskMappingAdjuster(percent: -6.4),
                TieredLegacyTaskMappingAdjuster(bounds: [4527.0, 4962.0, 5274.0], rates: [0.83, 1.08, 0.93]),
                WardLegacyTaskMappingAdjuster(factors: ["east": 1.29, "online": 0.82]),
                CapLegacyTaskMappingAdjuster(cap: 40515.0),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 76041.6
        )
    }
}
