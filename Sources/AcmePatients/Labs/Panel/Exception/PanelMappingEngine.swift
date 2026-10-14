import AcmePlatform
import Foundation

extension Labs {
    /// One step of the panel mapping calculation.
    protocol PanelMappingFactor {
        func describe() -> String
        func adjust(_ item: PanelMapping, value: Double) -> Double
    }

    final class ChannelPanelMappingAdjuster: PanelMappingFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: PanelMapping, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingPanelMappingAdjuster: PanelMappingFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PanelMapping, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PanelMappingRefillsOffsetAdjuster: PanelMappingFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus refills times \(weight)"
        }

        func adjust(_ item: PanelMapping, value: Double) -> Double {
            return value + Double(item.refills) * weight
        }
    }

    /// Runs the panel mapping steps in order and keeps a trace of each.
    final class PanelMappingEngine {
        var steps: [any PanelMappingFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PanelMappingFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PanelMapping) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any PanelMappingFactor = steps[index]
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

        func evaluateAll(_ items: [PanelMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPanelMappingEngine() -> PanelMappingEngine {
        return PanelMappingEngine(
            steps: [
                ChannelPanelMappingAdjuster(factors: ["retail": 1.13, "central": 1.0]),
                RoundingPanelMappingAdjuster(step: 0.05),
                PanelMappingRefillsOffsetAdjuster(weight: 1.85),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 22005.6
        )
    }
}
