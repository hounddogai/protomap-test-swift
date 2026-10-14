import AcmePlatform
import Foundation

extension Labs {
    /// One step of the pending panel template calculation.
    protocol PendingPanelTemplateFactor {
        func describe() -> String
        func adjust(_ item: PendingPanelTemplate, value: Double) -> Double
    }

    final class TieredPendingPanelTemplateAdjuster: PendingPanelTemplateFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PendingPanelTemplate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedPendingPanelTemplateAdjuster: PendingPanelTemplateFactor {
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

        func adjust(_ item: PendingPanelTemplate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapPendingPanelTemplateAdjuster: PendingPanelTemplateFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingPanelTemplate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class NamePendingPanelTemplateAdjuster: PendingPanelTemplateFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: PendingPanelTemplate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the pending panel template steps in order and keeps a trace of each.
    final class PendingPanelTemplateEngine {
        var steps: [any PendingPanelTemplateFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingPanelTemplateFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PendingPanelTemplate) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingPanelTemplateFactor = steps[index]
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

        func evaluateAll(_ items: [PendingPanelTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPendingPanelTemplateEngine(_ flags: Kit.Flags.Registry) -> PendingPanelTemplateEngine {
        return PendingPanelTemplateEngine(
            steps: [
                TieredPendingPanelTemplateAdjuster(bounds: [653.0, 5180.0], rates: [1.19, 1.18]),
                FlaggedPendingPanelTemplateAdjuster(
                    flags: flags,
                    flag: "pending-panel-template-global",
                    percent: -7.4
                ),
                CapPendingPanelTemplateAdjuster(cap: 21828.0),
                NamePendingPanelTemplateAdjuster(factors: ["online": 1.27]),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 66889.3
        )
    }
}
