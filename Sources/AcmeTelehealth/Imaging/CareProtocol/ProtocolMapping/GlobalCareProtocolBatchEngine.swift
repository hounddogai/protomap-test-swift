import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the global care protocol batch calculation.
    protocol GlobalCareProtocolBatchAdjuster {
        func describe() -> String
        func adjust(_ item: GlobalCareProtocolBatch, value: Double) -> Double
    }

    final class PercentGlobalCareProtocolBatchAdjuster: GlobalCareProtocolBatchAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalCareProtocolBatch, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredGlobalCareProtocolBatchAdjuster: GlobalCareProtocolBatchAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalCareProtocolBatch, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapGlobalCareProtocolBatchAdjuster: GlobalCareProtocolBatchAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalCareProtocolBatch, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the global care protocol batch steps in order and keeps a trace of each.
    final class GlobalCareProtocolBatchEngine {
        var steps: [any GlobalCareProtocolBatchAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalCareProtocolBatchAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: GlobalCareProtocolBatch) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalCareProtocolBatchAdjuster = steps[index]
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

        func evaluateAll(_ items: [GlobalCareProtocolBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultGlobalCareProtocolBatchEngine() -> GlobalCareProtocolBatchEngine {
        return GlobalCareProtocolBatchEngine(
            steps: [
                PercentGlobalCareProtocolBatchAdjuster(percent: 17.0),
                TieredGlobalCareProtocolBatchAdjuster(
                    bounds: [1352.0, 1627.0, 2018.0, 5800.0],
                    rates: [0.96, 1.05, 0.95, 0.9]
                ),
                CapGlobalCareProtocolBatchAdjuster(cap: 13958.0),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 11144.3
        )
    }
}
