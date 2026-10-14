import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the charge template calculation.
    protocol ChargeTemplateAdjuster {
        func describe() -> String
        func adjust(_ item: ChargeTemplate, value: Double) -> Double
    }

    final class CapChargeTemplateAdjuster: ChargeTemplateAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ChargeTemplate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingChargeTemplateAdjuster: ChargeTemplateAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ChargeTemplate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class SegmentChargeTemplateAdjuster: ChargeTemplateAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: ChargeTemplate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the charge template steps in order and keeps a trace of each.
    final class ChargeTemplateEngine {
        var steps: [any ChargeTemplateAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ChargeTemplateAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ChargeTemplate) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any ChargeTemplateAdjuster = steps[index]
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

        func evaluateAll(_ items: [ChargeTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultChargeTemplateEngine() -> ChargeTemplateEngine {
        return ChargeTemplateEngine(
            steps: [
                CapChargeTemplateAdjuster(cap: 12907.0),
                RoundingChargeTemplateAdjuster(step: 0.05),
                SegmentChargeTemplateAdjuster(factors: ["south": 1.35]),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 11485.6
        )
    }
}
