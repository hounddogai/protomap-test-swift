import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the global study notice calculation.
    protocol GlobalStudyNoticeModifier {
        func describe() -> String
        func adjust(_ item: GlobalStudyNotice, value: Double) -> Double
    }

    final class TieredGlobalStudyNoticeAdjuster: GlobalStudyNoticeModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalStudyNotice, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumGlobalStudyNoticeAdjuster: GlobalStudyNoticeModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalStudyNotice, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class GlobalStudyNoticeRefillsOffsetAdjuster: GlobalStudyNoticeModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus refills times \(weight)"
        }

        func adjust(_ item: GlobalStudyNotice, value: Double) -> Double {
            return value + Double(item.refills) * weight
        }
    }

    final class CapGlobalStudyNoticeAdjuster: GlobalStudyNoticeModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalStudyNotice, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class NameGlobalStudyNoticeAdjuster: GlobalStudyNoticeModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: GlobalStudyNotice, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentGlobalStudyNoticeAdjuster: GlobalStudyNoticeModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalStudyNotice, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the global study notice steps in order and keeps a trace of each.
    final class GlobalStudyNoticeEngine {
        var steps: [any GlobalStudyNoticeModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalStudyNoticeModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: GlobalStudyNotice) -> Double {
            var current = item.weightedTotal()
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

        func evaluateAll(_ items: [GlobalStudyNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultGlobalStudyNoticeEngine() -> GlobalStudyNoticeEngine {
        return GlobalStudyNoticeEngine(
            steps: [
                TieredGlobalStudyNoticeAdjuster(bounds: [1072.0, 1984.0], rates: [0.99, 0.87]),
                MinimumGlobalStudyNoticeAdjuster(minimum: 45.9),
                GlobalStudyNoticeRefillsOffsetAdjuster(weight: 0.66),
                CapGlobalStudyNoticeAdjuster(cap: 12229.0),
                NameGlobalStudyNoticeAdjuster(factors: ["south": 1.12, "north": 1.18, "retail": 1.06]),
                PercentGlobalStudyNoticeAdjuster(percent: -24.9),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 72830.5
        )
    }
}
