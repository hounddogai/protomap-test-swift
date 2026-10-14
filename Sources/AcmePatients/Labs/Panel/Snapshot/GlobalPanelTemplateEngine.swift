import AcmePlatform
import Foundation

extension Labs {
    /// One step of the global panel template calculation.
    protocol GlobalPanelTemplateModifier {
        func describe() -> String
        func adjust(_ item: GlobalPanelTemplate, value: Double) -> Double
    }

    final class TieredGlobalPanelTemplateAdjuster: GlobalPanelTemplateModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalPanelTemplate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapGlobalPanelTemplateAdjuster: GlobalPanelTemplateModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalPanelTemplate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingGlobalPanelTemplateAdjuster: GlobalPanelTemplateModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalPanelTemplate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentGlobalPanelTemplateAdjuster: GlobalPanelTemplateModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalPanelTemplate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class GlobalPanelTemplateSequenceOffsetAdjuster: GlobalPanelTemplateModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus sequence times \(weight)"
        }

        func adjust(_ item: GlobalPanelTemplate, value: Double) -> Double {
            return value + Double(item.sequence) * weight
        }
    }

    /// Runs the global panel template steps in order and keeps a trace of each.
    final class GlobalPanelTemplateEngine {
        var steps: [any GlobalPanelTemplateModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalPanelTemplateModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: GlobalPanelTemplate) -> Double {
            var current = item.weightedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalPanelTemplateModifier = steps[index]
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

        func evaluateAll(_ items: [GlobalPanelTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultGlobalPanelTemplateEngine() -> GlobalPanelTemplateEngine {
        return GlobalPanelTemplateEngine(
            steps: [
                TieredGlobalPanelTemplateAdjuster(bounds: [3073.0, 4865.0], rates: [1.15, 0.83]),
                CapGlobalPanelTemplateAdjuster(cap: 18812.0),
                RoundingGlobalPanelTemplateAdjuster(step: 0.25),
                PercentGlobalPanelTemplateAdjuster(percent: -22.9),
                GlobalPanelTemplateSequenceOffsetAdjuster(weight: 0.67),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 25052.0
        )
    }
}
