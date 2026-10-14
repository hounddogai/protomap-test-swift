import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the lenient denial manifest calculation.
    protocol LenientDenialManifestAdjuster {
        func describe() -> String
        func adjust(_ item: LenientDenialManifest, value: Double) -> Double
    }

    final class TieredLenientDenialManifestAdjuster: LenientDenialManifestAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientDenialManifest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapLenientDenialManifestAdjuster: LenientDenialManifestAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientDenialManifest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LabelLenientDenialManifestAdjuster: LenientDenialManifestAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: LenientDenialManifest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the lenient denial manifest steps in order and keeps a trace of each.
    final class LenientDenialManifestEngine {
        var steps: [any LenientDenialManifestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientDenialManifestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LenientDenialManifest) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientDenialManifestAdjuster = steps[index]
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

        func evaluateAll(_ items: [LenientDenialManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLenientDenialManifestEngine() -> LenientDenialManifestEngine {
        return LenientDenialManifestEngine(
            steps: [
                TieredLenientDenialManifestAdjuster(bounds: [3681.0, 9518.0], rates: [0.9, 1.01]),
                CapLenientDenialManifestAdjuster(cap: 24464.0),
                LabelLenientDenialManifestAdjuster(factors: ["south": 1.26, "east": 1.23, "retail": 1.16]),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 33778.3
        )
    }
}
