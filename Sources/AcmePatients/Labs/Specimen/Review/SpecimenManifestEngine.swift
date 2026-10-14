import AcmePlatform
import Foundation

extension Labs {
    /// One step of the specimen manifest calculation.
    protocol SpecimenManifestStep {
        func describe() -> String
        func adjust(_ item: SpecimenManifest, value: Double) -> Double
    }

    final class PercentSpecimenManifestAdjuster: SpecimenManifestStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SpecimenManifest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredSpecimenManifestAdjuster: SpecimenManifestStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SpecimenManifest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class SpecimenManifestAttemptsOffsetAdjuster: SpecimenManifestStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: SpecimenManifest, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    final class RoundingSpecimenManifestAdjuster: SpecimenManifestStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SpecimenManifest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapSpecimenManifestAdjuster: SpecimenManifestStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SpecimenManifest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the specimen manifest steps in order and keeps a trace of each.
    final class SpecimenManifestEngine {
        var steps: [any SpecimenManifestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SpecimenManifestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: SpecimenManifest) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any SpecimenManifestStep = steps[index]
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

        func evaluateAll(_ items: [SpecimenManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultSpecimenManifestEngine() -> SpecimenManifestEngine {
        return SpecimenManifestEngine(
            steps: [
                PercentSpecimenManifestAdjuster(percent: 19.5),
                TieredSpecimenManifestAdjuster(bounds: [2474.0, 3068.0], rates: [0.96, 0.8]),
                SpecimenManifestAttemptsOffsetAdjuster(weight: 1.46),
                RoundingSpecimenManifestAdjuster(step: 0.5),
                CapSpecimenManifestAdjuster(cap: 27988.0),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 98910.2
        )
    }
}
