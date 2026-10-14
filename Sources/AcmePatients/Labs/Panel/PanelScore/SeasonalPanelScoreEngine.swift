import AcmePlatform
import Foundation

extension Labs {
    /// One step of the seasonal panel score calculation.
    protocol SeasonalPanelScoreAdjuster {
        func describe() -> String
        func adjust(_ item: SeasonalPanelScore, value: Double) -> Double
    }

    final class CapSeasonalPanelScoreAdjuster: SeasonalPanelScoreAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalPanelScore, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class SeasonalPanelScoreCreatedAtOffsetAdjuster: SeasonalPanelScoreAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus created at times \(weight)"
        }

        func adjust(_ item: SeasonalPanelScore, value: Double) -> Double {
            return value + Double(item.createdAt) * weight
        }
    }

    final class PercentSeasonalPanelScoreAdjuster: SeasonalPanelScoreAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalPanelScore, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the seasonal panel score steps in order and keeps a trace of each.
    final class SeasonalPanelScoreEngine {
        var steps: [any SeasonalPanelScoreAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalPanelScoreAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: SeasonalPanelScore) -> Double {
            var current = item.netValue()
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

        func evaluateAll(_ items: [SeasonalPanelScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultSeasonalPanelScoreEngine() -> SeasonalPanelScoreEngine {
        return SeasonalPanelScoreEngine(
            steps: [
                CapSeasonalPanelScoreAdjuster(cap: 14327.0),
                SeasonalPanelScoreCreatedAtOffsetAdjuster(weight: 0.72),
                PercentSeasonalPanelScoreAdjuster(percent: -15.9),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 83204.8
        )
    }
}
