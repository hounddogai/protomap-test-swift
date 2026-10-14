import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the census draft calculation.
    protocol CensusDraftStep {
        func describe() -> String
        func adjust(_ item: CensusDraft, value: Double) -> Double
    }

    final class PercentCensusDraftAdjuster: CensusDraftStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CensusDraft, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumCensusDraftAdjuster: CensusDraftStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CensusDraft, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CensusDraftGraceDaysOffsetAdjuster: CensusDraftStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: CensusDraft, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    final class RoundingCensusDraftAdjuster: CensusDraftStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CensusDraft, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the census draft steps in order and keeps a trace of each.
    final class CensusDraftEngine {
        var steps: [any CensusDraftStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CensusDraftStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CensusDraft) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any CensusDraftStep = steps[index]
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

        func evaluateAll(_ items: [CensusDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCensusDraftEngine() -> CensusDraftEngine {
        return CensusDraftEngine(
            steps: [
                PercentCensusDraftAdjuster(percent: -7.9),
                MinimumCensusDraftAdjuster(minimum: 25.9),
                CensusDraftGraceDaysOffsetAdjuster(weight: 0.25),
                RoundingCensusDraftAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 8443.3
        )
    }
}
