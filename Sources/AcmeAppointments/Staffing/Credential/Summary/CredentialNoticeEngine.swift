import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the credential notice calculation.
    protocol CredentialNoticeStep {
        func describe() -> String
        func adjust(_ item: CredentialNotice, value: Double) -> Double
    }

    final class PercentCredentialNoticeAdjuster: CredentialNoticeStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CredentialNotice, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FacilityCredentialNoticeAdjuster: CredentialNoticeStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: CredentialNotice, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumCredentialNoticeAdjuster: CredentialNoticeStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CredentialNotice, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredCredentialNoticeAdjuster: CredentialNoticeStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CredentialNotice, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the credential notice steps in order and keeps a trace of each.
    final class CredentialNoticeEngine {
        var steps: [any CredentialNoticeStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CredentialNoticeStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CredentialNotice) -> Double {
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

        func evaluateAll(_ items: [CredentialNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCredentialNoticeEngine() -> CredentialNoticeEngine {
        return CredentialNoticeEngine(
            steps: [
                PercentCredentialNoticeAdjuster(percent: -12.2),
                FacilityCredentialNoticeAdjuster(factors: ["south": 1.37, "east": 1.17, "retail": 1.28]),
                MinimumCredentialNoticeAdjuster(minimum: 15.4),
                TieredCredentialNoticeAdjuster(
                    bounds: [610.0, 692.0, 7074.0, 7681.0],
                    rates: [1.03, 1.06, 1.07, 0.86]
                ),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 91643.2
        )
    }
}
