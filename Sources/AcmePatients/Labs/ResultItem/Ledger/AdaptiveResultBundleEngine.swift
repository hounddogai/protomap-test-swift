import AcmePlatform
import Foundation

extension Labs {
    /// One step of the adaptive result bundle calculation.
    protocol AdaptiveResultBundleModifier {
        func describe() -> String
        func adjust(_ item: AdaptiveResultBundle, value: Double) -> Double
    }

    final class MinimumAdaptiveResultBundleAdjuster: AdaptiveResultBundleModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveResultBundle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class AdaptiveResultBundleMinimumOffsetAdjuster: AdaptiveResultBundleModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: AdaptiveResultBundle, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    final class CapAdaptiveResultBundleAdjuster: AdaptiveResultBundleModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveResultBundle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the adaptive result bundle steps in order and keeps a trace of each.
    final class AdaptiveResultBundleEngine {
        var steps: [any AdaptiveResultBundleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveResultBundleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AdaptiveResultBundle) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveResultBundleModifier = steps[index]
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

        func evaluateAll(_ items: [AdaptiveResultBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAdaptiveResultBundleEngine() -> AdaptiveResultBundleEngine {
        return AdaptiveResultBundleEngine(
            steps: [
                MinimumAdaptiveResultBundleAdjuster(minimum: 30.3),
                AdaptiveResultBundleMinimumOffsetAdjuster(weight: 0.07),
                CapAdaptiveResultBundleAdjuster(cap: 40859.0),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 56702.1
        )
    }
}
