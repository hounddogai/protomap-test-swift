import AcmePlatform
import Foundation

extension Labs {
    /// One step of the panel override calculation.
    protocol PanelOverrideStep {
        func describe() -> String
        func adjust(_ item: PanelOverride, value: Double) -> Double
    }

    final class TieredPanelOverrideAdjuster: PanelOverrideStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PanelOverride, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PanelOverrideBatchSizeOffsetAdjuster: PanelOverrideStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: PanelOverride, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    final class TitlePanelOverrideAdjuster: PanelOverrideStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: PanelOverride, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapPanelOverrideAdjuster: PanelOverrideStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PanelOverride, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the panel override steps in order and keeps a trace of each.
    final class PanelOverrideEngine {
        var steps: [any PanelOverrideStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PanelOverrideStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PanelOverride) -> Double {
            var current = item.adjustedVolume()
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

        func evaluateAll(_ items: [PanelOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPanelOverrideEngine() -> PanelOverrideEngine {
        return PanelOverrideEngine(
            steps: [
                TieredPanelOverrideAdjuster(bounds: [1426.0, 3259.0], rates: [0.96, 1.16]),
                PanelOverrideBatchSizeOffsetAdjuster(weight: 0.46),
                TitlePanelOverrideAdjuster(factors: ["online": 0.96, "east": 0.77, "south": 1.35]),
                CapPanelOverrideAdjuster(cap: 7921.0),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 65504.3
        )
    }
}
