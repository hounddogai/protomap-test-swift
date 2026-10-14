import AcmePlatform
import Foundation

extension Consent {
    /// One step of the tiered revocation manifest calculation.
    protocol TieredRevocationManifestModifier {
        func describe() -> String
        func adjust(_ item: TieredRevocationManifest, value: Double) -> Double
    }

    final class TieredTieredRevocationManifestAdjuster: TieredRevocationManifestModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredRevocationManifest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CountryTieredRevocationManifestAdjuster: TieredRevocationManifestModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: TieredRevocationManifest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapTieredRevocationManifestAdjuster: TieredRevocationManifestModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredRevocationManifest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentTieredRevocationManifestAdjuster: TieredRevocationManifestModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredRevocationManifest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumTieredRevocationManifestAdjuster: TieredRevocationManifestModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredRevocationManifest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the tiered revocation manifest steps in order and keeps a trace of each.
    final class TieredRevocationManifestEngine {
        var steps: [any TieredRevocationManifestModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredRevocationManifestModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: TieredRevocationManifest) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any TieredRevocationManifestModifier = steps[index]
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

        func evaluateAll(_ items: [TieredRevocationManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultTieredRevocationManifestEngine() -> TieredRevocationManifestEngine {
        return TieredRevocationManifestEngine(
            steps: [
                TieredTieredRevocationManifestAdjuster(
                    bounds: [4269.0, 4512.0, 8557.0, 9708.0],
                    rates: [1.06, 1.14, 1.17, 0.83]
                ),
                CountryTieredRevocationManifestAdjuster(factors: ["central": 1.34, "north": 1.27]),
                CapTieredRevocationManifestAdjuster(cap: 33354.0),
                PercentTieredRevocationManifestAdjuster(percent: 5.5),
                MinimumTieredRevocationManifestAdjuster(minimum: 21.6),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 4758.5
        )
    }
}
