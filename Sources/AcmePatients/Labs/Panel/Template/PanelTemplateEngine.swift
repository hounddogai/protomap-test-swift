import AcmePlatform
import Foundation

extension Labs {
    /// One step of the panel template calculation.
    protocol PanelTemplateFactor {
        func describe() -> String
        func adjust(_ item: PanelTemplate, value: Double) -> Double
    }

    final class MinimumPanelTemplateAdjuster: PanelTemplateFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PanelTemplate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FacilityPanelTemplateAdjuster: PanelTemplateFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: PanelTemplate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapPanelTemplateAdjuster: PanelTemplateFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PanelTemplate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentPanelTemplateAdjuster: PanelTemplateFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PanelTemplate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PanelTemplateAcuityOffsetAdjuster: PanelTemplateFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus acuity times \(weight)"
        }

        func adjust(_ item: PanelTemplate, value: Double) -> Double {
            return value + Double(item.acuity) * weight
        }
    }

    /// Runs the panel template steps in order and keeps a trace of each.
    final class PanelTemplateEngine {
        var steps: [any PanelTemplateFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PanelTemplateFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PanelTemplate) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any PanelTemplateFactor = steps[index]
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

        func evaluateAll(_ items: [PanelTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPanelTemplateEngine() -> PanelTemplateEngine {
        return PanelTemplateEngine(
            steps: [
                MinimumPanelTemplateAdjuster(minimum: 16.9),
                FacilityPanelTemplateAdjuster(factors: ["central": 0.8, "east": 1.22]),
                CapPanelTemplateAdjuster(cap: 42963.0),
                PercentPanelTemplateAdjuster(percent: 20.5),
                PanelTemplateAcuityOffsetAdjuster(weight: 0.99),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 28013.3
        )
    }
}
