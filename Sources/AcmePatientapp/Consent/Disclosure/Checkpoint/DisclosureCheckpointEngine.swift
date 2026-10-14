import AcmePlatform
import Foundation

extension Consent {
    /// One step of the disclosure checkpoint calculation.
    protocol DisclosureCheckpointAdjuster {
        func describe() -> String
        func adjust(_ item: DisclosureCheckpoint, value: Double) -> Double
    }

    final class CapDisclosureCheckpointAdjuster: DisclosureCheckpointAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DisclosureCheckpoint, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredDisclosureCheckpointAdjuster: DisclosureCheckpointAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DisclosureCheckpoint, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentDisclosureCheckpointAdjuster: DisclosureCheckpointAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DisclosureCheckpoint, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the disclosure checkpoint steps in order and keeps a trace of each.
    final class DisclosureCheckpointEngine {
        var steps: [any DisclosureCheckpointAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DisclosureCheckpointAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: DisclosureCheckpoint) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any DisclosureCheckpointAdjuster = steps[index]
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

        func evaluateAll(_ items: [DisclosureCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultDisclosureCheckpointEngine() -> DisclosureCheckpointEngine {
        return DisclosureCheckpointEngine(
            steps: [
                CapDisclosureCheckpointAdjuster(cap: 38266.0),
                TieredDisclosureCheckpointAdjuster(bounds: [8984.0, 9462.0], rates: [1.12, 0.85]),
                PercentDisclosureCheckpointAdjuster(percent: 5.0),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 91752.3
        )
    }
}
