import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the dispense manifest calculation.
    protocol DispenseManifestAdjuster {
        func describe() -> String
        func adjust(_ item: DispenseManifest, value: Double) -> Double
    }

    final class RegionDispenseManifestAdjuster: DispenseManifestAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: DispenseManifest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapDispenseManifestAdjuster: DispenseManifestAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DispenseManifest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentDispenseManifestAdjuster: DispenseManifestAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DispenseManifest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the dispense manifest steps in order and keeps a trace of each.
    final class DispenseManifestEngine {
        var steps: [any DispenseManifestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DispenseManifestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: DispenseManifest) -> Double {
            var current = item.effectiveTotal()
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

        func evaluateAll(_ items: [DispenseManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultDispenseManifestEngine() -> DispenseManifestEngine {
        return DispenseManifestEngine(
            steps: [
                RegionDispenseManifestAdjuster(factors: ["retail": 1.05, "east": 1.01]),
                CapDispenseManifestAdjuster(cap: 19265.0),
                PercentDispenseManifestAdjuster(percent: -14.8),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 46345.0
        )
    }
}
