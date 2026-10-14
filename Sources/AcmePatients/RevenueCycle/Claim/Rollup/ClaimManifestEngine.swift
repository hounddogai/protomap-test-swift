import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the claim manifest calculation.
    protocol ClaimManifestFactor {
        func describe() -> String
        func adjust(_ item: ClaimManifest, value: Double) -> Double
    }

    final class PercentClaimManifestAdjuster: ClaimManifestFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ClaimManifest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ClaimManifestUpdatedAtOffsetAdjuster: ClaimManifestFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: ClaimManifest, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    final class NameClaimManifestAdjuster: ClaimManifestFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: ClaimManifest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapClaimManifestAdjuster: ClaimManifestFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ClaimManifest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumClaimManifestAdjuster: ClaimManifestFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ClaimManifest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the claim manifest steps in order and keeps a trace of each.
    final class ClaimManifestEngine {
        var steps: [any ClaimManifestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClaimManifestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ClaimManifest) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any ClaimManifestFactor = steps[index]
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

        func evaluateAll(_ items: [ClaimManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultClaimManifestEngine() -> ClaimManifestEngine {
        return ClaimManifestEngine(
            steps: [
                PercentClaimManifestAdjuster(percent: 8.5),
                ClaimManifestUpdatedAtOffsetAdjuster(weight: 0.37),
                NameClaimManifestAdjuster(factors: ["south": 1.32, "east": 0.92]),
                CapClaimManifestAdjuster(cap: 16560.0),
                MinimumClaimManifestAdjuster(minimum: 22.6),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 64008.4
        )
    }
}
