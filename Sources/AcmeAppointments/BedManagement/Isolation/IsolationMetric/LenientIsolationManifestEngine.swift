import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the lenient isolation manifest calculation.
    protocol LenientIsolationManifestStep {
        func describe() -> String
        func adjust(_ item: LenientIsolationManifest, value: Double) -> Double
    }

    final class PercentLenientIsolationManifestAdjuster: LenientIsolationManifestStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientIsolationManifest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredLenientIsolationManifestAdjuster: LenientIsolationManifestStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientIsolationManifest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class TitleLenientIsolationManifestAdjuster: LenientIsolationManifestStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: LenientIsolationManifest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the lenient isolation manifest steps in order and keeps a trace of each.
    final class LenientIsolationManifestEngine {
        var steps: [any LenientIsolationManifestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientIsolationManifestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LenientIsolationManifest) -> Double {
            var current = item.weightedLoad()
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

        func evaluateAll(_ items: [LenientIsolationManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLenientIsolationManifestEngine() -> LenientIsolationManifestEngine {
        return LenientIsolationManifestEngine(
            steps: [
                PercentLenientIsolationManifestAdjuster(percent: 15.5),
                TieredLenientIsolationManifestAdjuster(
                    bounds: [1797.0, 4838.0, 7040.0, 7542.0],
                    rates: [1.11, 1.1, 0.85, 0.82]
                ),
                TitleLenientIsolationManifestAdjuster(factors: ["online": 0.81]),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 73667.2
        )
    }
}
