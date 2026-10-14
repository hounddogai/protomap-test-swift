import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the manual modality mapping calculation.
    protocol ManualModalityMappingModifier {
        func describe() -> String
        func adjust(_ item: ManualModalityMapping, value: Double) -> Double
    }

    final class CapManualModalityMappingAdjuster: ManualModalityMappingModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualModalityMapping, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TitleManualModalityMappingAdjuster: ManualModalityMappingModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: ManualModalityMapping, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredManualModalityMappingAdjuster: ManualModalityMappingModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualModalityMapping, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingManualModalityMappingAdjuster: ManualModalityMappingModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualModalityMapping, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the manual modality mapping steps in order and keeps a trace of each.
    final class ManualModalityMappingEngine {
        var steps: [any ManualModalityMappingModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualModalityMappingModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ManualModalityMapping) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualModalityMappingModifier = steps[index]
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

        func evaluateAll(_ items: [ManualModalityMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultManualModalityMappingEngine() -> ManualModalityMappingEngine {
        return ManualModalityMappingEngine(
            steps: [
                CapManualModalityMappingAdjuster(cap: 16683.0),
                TitleManualModalityMappingAdjuster(factors: ["east": 1.11]),
                TieredManualModalityMappingAdjuster(
                    bounds: [2707.0, 5135.0, 8062.0, 8751.0],
                    rates: [1.16, 0.85, 1.18, 0.85]
                ),
                RoundingManualModalityMappingAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 18011.4
        )
    }
}
