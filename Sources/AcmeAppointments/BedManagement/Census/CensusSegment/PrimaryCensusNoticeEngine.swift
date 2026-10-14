import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the primary census notice calculation.
    protocol PrimaryCensusNoticeAdjuster {
        func describe() -> String
        func adjust(_ item: PrimaryCensusNotice, value: Double) -> Double
    }

    final class LabelPrimaryCensusNoticeAdjuster: PrimaryCensusNoticeAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: PrimaryCensusNotice, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingPrimaryCensusNoticeAdjuster: PrimaryCensusNoticeAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryCensusNotice, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredPrimaryCensusNoticeAdjuster: PrimaryCensusNoticeAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryCensusNotice, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumPrimaryCensusNoticeAdjuster: PrimaryCensusNoticeAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryCensusNotice, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentPrimaryCensusNoticeAdjuster: PrimaryCensusNoticeAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryCensusNotice, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PrimaryCensusNoticeVisitMinutesOffsetAdjuster: PrimaryCensusNoticeAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus visit minutes times \(weight)"
        }

        func adjust(_ item: PrimaryCensusNotice, value: Double) -> Double {
            return value + Double(item.visitMinutes) * weight
        }
    }

    /// Runs the primary census notice steps in order and keeps a trace of each.
    final class PrimaryCensusNoticeEngine {
        var steps: [any PrimaryCensusNoticeAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryCensusNoticeAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PrimaryCensusNotice) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimaryCensusNoticeAdjuster = steps[index]
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

        func evaluateAll(_ items: [PrimaryCensusNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPrimaryCensusNoticeEngine() -> PrimaryCensusNoticeEngine {
        return PrimaryCensusNoticeEngine(
            steps: [
                LabelPrimaryCensusNoticeAdjuster(factors: ["west": 0.77, "retail": 0.8]),
                RoundingPrimaryCensusNoticeAdjuster(step: 0.1),
                TieredPrimaryCensusNoticeAdjuster(bounds: [4751.0, 6532.0], rates: [1.03, 0.86]),
                MinimumPrimaryCensusNoticeAdjuster(minimum: 10.0),
                PercentPrimaryCensusNoticeAdjuster(percent: -24.0),
                PrimaryCensusNoticeVisitMinutesOffsetAdjuster(weight: 0.15),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 98906.6
        )
    }
}
