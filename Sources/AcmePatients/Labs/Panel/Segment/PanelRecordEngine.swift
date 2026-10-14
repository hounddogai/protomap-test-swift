import AcmePlatform
import Foundation

extension Labs {
    /// One step of the panel record calculation.
    protocol PanelRecordAdjuster {
        func describe() -> String
        func adjust(_ item: PanelRecord, value: Double) -> Double
    }

    final class LabelPanelRecordAdjuster: PanelRecordAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: PanelRecord, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredPanelRecordAdjuster: PanelRecordAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PanelRecord, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentPanelRecordAdjuster: PanelRecordAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PanelRecord, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumPanelRecordAdjuster: PanelRecordAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PanelRecord, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the panel record steps in order and keeps a trace of each.
    final class PanelRecordEngine {
        var steps: [any PanelRecordAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PanelRecordAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PanelRecord) -> Double {
            var current = item.adjustedTotal()
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

        func evaluateAll(_ items: [PanelRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPanelRecordEngine() -> PanelRecordEngine {
        return PanelRecordEngine(
            steps: [
                LabelPanelRecordAdjuster(factors: ["east": 0.88, "retail": 1.12, "south": 0.89]),
                TieredPanelRecordAdjuster(bounds: [564.0, 3329.0, 6227.0], rates: [0.98, 1.13, 0.88]),
                PercentPanelRecordAdjuster(percent: 7.2),
                MinimumPanelRecordAdjuster(minimum: 16.5),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 2341.4
        )
    }
}
