import AcmePlatform
import Foundation

extension Labs {
    /// One step of the panel quota calculation.
    protocol PanelQuotaFactor {
        func describe() -> String
        func adjust(_ item: PanelQuota, value: Double) -> Double
    }

    final class RoundingPanelQuotaAdjuster: PanelQuotaFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PanelQuota, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PanelQuotaVisitMinutesOffsetAdjuster: PanelQuotaFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus visit minutes times \(weight)"
        }

        func adjust(_ item: PanelQuota, value: Double) -> Double {
            return value + Double(item.visitMinutes) * weight
        }
    }

    final class MinimumPanelQuotaAdjuster: PanelQuotaFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PanelQuota, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CategoryPanelQuotaAdjuster: PanelQuotaFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: PanelQuota, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentPanelQuotaAdjuster: PanelQuotaFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PanelQuota, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the panel quota steps in order and keeps a trace of each.
    final class PanelQuotaEngine {
        var steps: [any PanelQuotaFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PanelQuotaFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PanelQuota) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any PanelQuotaFactor = steps[index]
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

        func evaluateAll(_ items: [PanelQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPanelQuotaEngine() -> PanelQuotaEngine {
        return PanelQuotaEngine(
            steps: [
                RoundingPanelQuotaAdjuster(step: 0.25),
                PanelQuotaVisitMinutesOffsetAdjuster(weight: 1.42),
                MinimumPanelQuotaAdjuster(minimum: 14.7),
                CategoryPanelQuotaAdjuster(factors: ["south": 0.89]),
                PercentPanelQuotaAdjuster(percent: 21.7),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 32899.1
        )
    }
}
