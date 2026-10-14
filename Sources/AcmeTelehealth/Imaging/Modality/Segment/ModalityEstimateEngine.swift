import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the modality estimate calculation.
    protocol ModalityEstimateModifier {
        func describe() -> String
        func adjust(_ item: ModalityEstimate, value: Double) -> Double
    }

    final class PercentModalityEstimateAdjuster: ModalityEstimateModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ModalityEstimate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapModalityEstimateAdjuster: ModalityEstimateModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ModalityEstimate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedModalityEstimateAdjuster: ModalityEstimateModifier {
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

        func adjust(_ item: ModalityEstimate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the modality estimate steps in order and keeps a trace of each.
    final class ModalityEstimateEngine {
        var steps: [any ModalityEstimateModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ModalityEstimateModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ModalityEstimate) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ModalityEstimateModifier = steps[index]
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

        func evaluateAll(_ items: [ModalityEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultModalityEstimateEngine(_ flags: Kit.Flags.Registry) -> ModalityEstimateEngine {
        return ModalityEstimateEngine(
            steps: [
                PercentModalityEstimateAdjuster(percent: -4.2),
                CapModalityEstimateAdjuster(cap: 25128.0),
                FlaggedModalityEstimateAdjuster(flags: flags, flag: "modality-estimate-weighted", percent: 7.0),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 53265.6
        )
    }
}
