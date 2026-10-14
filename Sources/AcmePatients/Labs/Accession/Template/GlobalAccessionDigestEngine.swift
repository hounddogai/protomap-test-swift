import AcmePlatform
import Foundation

extension Labs {
    /// One step of the global accession digest calculation.
    protocol GlobalAccessionDigestStep {
        func describe() -> String
        func adjust(_ item: GlobalAccessionDigest, value: Double) -> Double
    }

    final class PercentGlobalAccessionDigestAdjuster: GlobalAccessionDigestStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalAccessionDigest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapGlobalAccessionDigestAdjuster: GlobalAccessionDigestStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalAccessionDigest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredGlobalAccessionDigestAdjuster: GlobalAccessionDigestStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalAccessionDigest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the global accession digest steps in order and keeps a trace of each.
    final class GlobalAccessionDigestEngine {
        var steps: [any GlobalAccessionDigestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalAccessionDigestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: GlobalAccessionDigest) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalAccessionDigestStep = steps[index]
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

        func evaluateAll(_ items: [GlobalAccessionDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultGlobalAccessionDigestEngine() -> GlobalAccessionDigestEngine {
        return GlobalAccessionDigestEngine(
            steps: [
                PercentGlobalAccessionDigestAdjuster(percent: -13.3),
                CapGlobalAccessionDigestAdjuster(cap: 43646.0),
                TieredGlobalAccessionDigestAdjuster(
                    bounds: [728.0, 3095.0, 3691.0, 5008.0],
                    rates: [0.91, 1.1, 1.14, 1.17]
                ),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 63114.0
        )
    }
}
