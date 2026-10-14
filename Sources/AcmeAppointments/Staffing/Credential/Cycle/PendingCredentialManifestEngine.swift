import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the pending credential manifest calculation.
    protocol PendingCredentialManifestAdjuster {
        func describe() -> String
        func adjust(_ item: PendingCredentialManifest, value: Double) -> Double
    }

    final class MinimumPendingCredentialManifestAdjuster: PendingCredentialManifestAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingCredentialManifest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredPendingCredentialManifestAdjuster: PendingCredentialManifestAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PendingCredentialManifest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapPendingCredentialManifestAdjuster: PendingCredentialManifestAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingCredentialManifest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LabelPendingCredentialManifestAdjuster: PendingCredentialManifestAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: PendingCredentialManifest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the pending credential manifest steps in order and keeps a trace of each.
    final class PendingCredentialManifestEngine {
        var steps: [any PendingCredentialManifestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingCredentialManifestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PendingCredentialManifest) -> Double {
            var current = item.adjustedExposure()
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

        func evaluateAll(_ items: [PendingCredentialManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPendingCredentialManifestEngine() -> PendingCredentialManifestEngine {
        return PendingCredentialManifestEngine(
            steps: [
                MinimumPendingCredentialManifestAdjuster(minimum: 2.2),
                TieredPendingCredentialManifestAdjuster(
                    bounds: [2156.0, 3091.0, 7185.0, 9372.0],
                    rates: [0.82, 0.93, 0.97, 1.0]
                ),
                CapPendingCredentialManifestAdjuster(cap: 17617.0),
                LabelPendingCredentialManifestAdjuster(factors: ["online": 1.13]),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 4365.6
        )
    }
}
