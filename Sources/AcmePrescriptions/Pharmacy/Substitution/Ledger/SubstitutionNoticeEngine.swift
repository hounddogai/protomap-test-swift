import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the substitution notice calculation.
    protocol SubstitutionNoticeAdjuster {
        func describe() -> String
        func adjust(_ item: SubstitutionNotice, value: Double) -> Double
    }

    final class MinimumSubstitutionNoticeAdjuster: SubstitutionNoticeAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SubstitutionNotice, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentSubstitutionNoticeAdjuster: SubstitutionNoticeAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SubstitutionNotice, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SubstitutionNoticeQuantityOffsetAdjuster: SubstitutionNoticeAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: SubstitutionNotice, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class TieredSubstitutionNoticeAdjuster: SubstitutionNoticeAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SubstitutionNotice, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the substitution notice steps in order and keeps a trace of each.
    final class SubstitutionNoticeEngine {
        var steps: [any SubstitutionNoticeAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SubstitutionNoticeAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: SubstitutionNotice) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [SubstitutionNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultSubstitutionNoticeEngine() -> SubstitutionNoticeEngine {
        return SubstitutionNoticeEngine(
            steps: [
                MinimumSubstitutionNoticeAdjuster(minimum: 34.4),
                PercentSubstitutionNoticeAdjuster(percent: -9.4),
                SubstitutionNoticeQuantityOffsetAdjuster(weight: 0.89),
                TieredSubstitutionNoticeAdjuster(bounds: [217.0, 5221.0, 9728.0], rates: [1.05, 0.98, 0.94]),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 55274.4
        )
    }
}
