import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the care protocol adjustment calculation.
    protocol CareProtocolAdjustmentStep {
        func describe() -> String
        func adjust(_ item: CareProtocolAdjustment, value: Double) -> Double
    }

    final class RoundingCareProtocolAdjustmentAdjuster: CareProtocolAdjustmentStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CareProtocolAdjustment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentCareProtocolAdjustmentAdjuster: CareProtocolAdjustmentStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CareProtocolAdjustment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredCareProtocolAdjustmentAdjuster: CareProtocolAdjustmentStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CareProtocolAdjustment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapCareProtocolAdjustmentAdjuster: CareProtocolAdjustmentStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CareProtocolAdjustment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class CareProtocolAdjustmentCeilingOffsetAdjuster: CareProtocolAdjustmentStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ceiling times \(weight)"
        }

        func adjust(_ item: CareProtocolAdjustment, value: Double) -> Double {
            return value + item.ceiling * weight
        }
    }

    /// Runs the care protocol adjustment steps in order and keeps a trace of each.
    final class CareProtocolAdjustmentEngine {
        var steps: [any CareProtocolAdjustmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareProtocolAdjustmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CareProtocolAdjustment) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any CareProtocolAdjustmentStep = steps[index]
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

        func evaluateAll(_ items: [CareProtocolAdjustment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCareProtocolAdjustmentEngine() -> CareProtocolAdjustmentEngine {
        return CareProtocolAdjustmentEngine(
            steps: [
                RoundingCareProtocolAdjustmentAdjuster(step: 0.5),
                PercentCareProtocolAdjustmentAdjuster(percent: -0.0),
                TieredCareProtocolAdjustmentAdjuster(bounds: [936.0, 3461.0], rates: [0.98, 1.03]),
                CapCareProtocolAdjustmentAdjuster(cap: 41872.0),
                CareProtocolAdjustmentCeilingOffsetAdjuster(weight: 1.12),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 54228.1
        )
    }
}
