import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the modality variance calculation.
    protocol ModalityVarianceStep {
        func describe() -> String
        func adjust(_ item: ModalityVariance, value: Double) -> Double
    }

    final class FlaggedModalityVarianceAdjuster: ModalityVarianceStep {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: ModalityVariance, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumModalityVarianceAdjuster: ModalityVarianceStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ModalityVariance, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredModalityVarianceAdjuster: ModalityVarianceStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ModalityVariance, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapModalityVarianceAdjuster: ModalityVarianceStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ModalityVariance, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the modality variance steps in order and keeps a trace of each.
    final class ModalityVarianceEngine {
        var steps: [any ModalityVarianceStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ModalityVarianceStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ModalityVariance) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any ModalityVarianceStep = steps[index]
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

        func evaluateAll(_ items: [ModalityVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultModalityVarianceEngine(_ flags: Kit.Flags.Registry) -> ModalityVarianceEngine {
        return ModalityVarianceEngine(
            steps: [
                FlaggedModalityVarianceAdjuster(flags: flags, flag: "modality-variance-batched", percent: 6.1),
                MinimumModalityVarianceAdjuster(minimum: 4.3),
                TieredModalityVarianceAdjuster(bounds: [9145.0, 9285.0], rates: [1.04, 0.85]),
                CapModalityVarianceAdjuster(cap: 12758.0),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 59850.2
        )
    }
}
