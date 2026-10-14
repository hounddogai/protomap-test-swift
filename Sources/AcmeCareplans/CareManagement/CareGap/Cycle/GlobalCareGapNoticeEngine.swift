import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the global care gap notice calculation.
    protocol GlobalCareGapNoticeStep {
        func describe() -> String
        func adjust(_ item: GlobalCareGapNotice, value: Double) -> Double
    }

    final class TieredGlobalCareGapNoticeAdjuster: GlobalCareGapNoticeStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalCareGapNotice, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumGlobalCareGapNoticeAdjuster: GlobalCareGapNoticeStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalCareGapNotice, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingGlobalCareGapNoticeAdjuster: GlobalCareGapNoticeStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalCareGapNotice, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentGlobalCareGapNoticeAdjuster: GlobalCareGapNoticeStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalCareGapNotice, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class GlobalCareGapNoticeDosageMgOffsetAdjuster: GlobalCareGapNoticeStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus dosage mg times \(weight)"
        }

        func adjust(_ item: GlobalCareGapNotice, value: Double) -> Double {
            return value + item.dosageMg * weight
        }
    }

    /// Runs the global care gap notice steps in order and keeps a trace of each.
    final class GlobalCareGapNoticeEngine {
        var steps: [any GlobalCareGapNoticeStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalCareGapNoticeStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: GlobalCareGapNotice) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalCareGapNoticeStep = steps[index]
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

        func evaluateAll(_ items: [GlobalCareGapNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultGlobalCareGapNoticeEngine() -> GlobalCareGapNoticeEngine {
        return GlobalCareGapNoticeEngine(
            steps: [
                TieredGlobalCareGapNoticeAdjuster(bounds: [1178.0, 1612.0, 6651.0], rates: [1.03, 1.08, 1.11]),
                MinimumGlobalCareGapNoticeAdjuster(minimum: 38.5),
                RoundingGlobalCareGapNoticeAdjuster(step: 0.05),
                PercentGlobalCareGapNoticeAdjuster(percent: 19.1),
                GlobalCareGapNoticeDosageMgOffsetAdjuster(weight: 1.09),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 37281.1
        )
    }
}
