import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the bed board template calculation.
    protocol BedBoardTemplateFactor {
        func describe() -> String
        func adjust(_ item: BedBoardTemplate, value: Double) -> Double
    }

    final class BedBoardTemplateBudgetOffsetAdjuster: BedBoardTemplateFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus budget times \(weight)"
        }

        func adjust(_ item: BedBoardTemplate, value: Double) -> Double {
            return value + item.budget * weight
        }
    }

    final class MinimumBedBoardTemplateAdjuster: BedBoardTemplateFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BedBoardTemplate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentBedBoardTemplateAdjuster: BedBoardTemplateFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BedBoardTemplate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the bed board template steps in order and keeps a trace of each.
    final class BedBoardTemplateEngine {
        var steps: [any BedBoardTemplateFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BedBoardTemplateFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: BedBoardTemplate) -> Double {
            var current = item.adjustedLoad()
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

        func evaluateAll(_ items: [BedBoardTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultBedBoardTemplateEngine() -> BedBoardTemplateEngine {
        return BedBoardTemplateEngine(
            steps: [
                BedBoardTemplateBudgetOffsetAdjuster(weight: 1.84),
                MinimumBedBoardTemplateAdjuster(minimum: 37.6),
                PercentBedBoardTemplateAdjuster(percent: -9.6),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 79169.9
        )
    }
}
