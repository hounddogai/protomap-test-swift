import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the adaptive network snapshot calculation.
    protocol AdaptiveNetworkSnapshotFactor {
        func describe() -> String
        func adjust(_ item: AdaptiveNetworkSnapshot, value: Double) -> Double
    }

    final class TieredAdaptiveNetworkSnapshotAdjuster: AdaptiveNetworkSnapshotFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveNetworkSnapshot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapAdaptiveNetworkSnapshotAdjuster: AdaptiveNetworkSnapshotFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveNetworkSnapshot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LabelAdaptiveNetworkSnapshotAdjuster: AdaptiveNetworkSnapshotFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: AdaptiveNetworkSnapshot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the adaptive network snapshot steps in order and keeps a trace of each.
    final class AdaptiveNetworkSnapshotEngine {
        var steps: [any AdaptiveNetworkSnapshotFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveNetworkSnapshotFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AdaptiveNetworkSnapshot) -> Double {
            var current = item.adjustedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveNetworkSnapshotFactor = steps[index]
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

        func evaluateAll(_ items: [AdaptiveNetworkSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAdaptiveNetworkSnapshotEngine() -> AdaptiveNetworkSnapshotEngine {
        return AdaptiveNetworkSnapshotEngine(
            steps: [
                TieredAdaptiveNetworkSnapshotAdjuster(bounds: [381.0, 1685.0, 1828.0], rates: [0.89, 0.91, 1.13]),
                CapAdaptiveNetworkSnapshotAdjuster(cap: 24466.0),
                LabelAdaptiveNetworkSnapshotAdjuster(factors: ["south": 1.28]),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 63844.3
        )
    }
}
