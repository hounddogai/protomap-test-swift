import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the strict interaction manifest calculation.
    protocol StrictInteractionManifestAdjuster {
        func describe() -> String
        func adjust(_ item: StrictInteractionManifest, value: Double) -> Double
    }

    final class RoundingStrictInteractionManifestAdjuster: StrictInteractionManifestAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictInteractionManifest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapStrictInteractionManifestAdjuster: StrictInteractionManifestAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StrictInteractionManifest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentStrictInteractionManifestAdjuster: StrictInteractionManifestAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StrictInteractionManifest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the strict interaction manifest steps in order and keeps a trace of each.
    final class StrictInteractionManifestEngine {
        var steps: [any StrictInteractionManifestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictInteractionManifestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: StrictInteractionManifest) -> Double {
            var current = item.projectedExposure()
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

        func evaluateAll(_ items: [StrictInteractionManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultStrictInteractionManifestEngine() -> StrictInteractionManifestEngine {
        return StrictInteractionManifestEngine(
            steps: [
                RoundingStrictInteractionManifestAdjuster(step: 0.5),
                CapStrictInteractionManifestAdjuster(cap: 38022.0),
                PercentStrictInteractionManifestAdjuster(percent: -23.5),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 12162.1
        )
    }
}
