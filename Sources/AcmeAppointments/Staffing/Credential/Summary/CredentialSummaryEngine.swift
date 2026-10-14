import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the credential summary calculation.
    protocol CredentialSummaryAdjuster {
        func describe() -> String
        func adjust(_ item: CredentialSummary, value: Double) -> Double
    }

    final class ChannelCredentialSummaryAdjuster: CredentialSummaryAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: CredentialSummary, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CredentialSummaryUpdatedAtOffsetAdjuster: CredentialSummaryAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: CredentialSummary, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    final class PercentCredentialSummaryAdjuster: CredentialSummaryAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CredentialSummary, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapCredentialSummaryAdjuster: CredentialSummaryAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CredentialSummary, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredCredentialSummaryAdjuster: CredentialSummaryAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CredentialSummary, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the credential summary steps in order and keeps a trace of each.
    final class CredentialSummaryEngine {
        var steps: [any CredentialSummaryAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CredentialSummaryAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CredentialSummary) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any CredentialSummaryAdjuster = steps[index]
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

        func evaluateAll(_ items: [CredentialSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCredentialSummaryEngine() -> CredentialSummaryEngine {
        return CredentialSummaryEngine(
            steps: [
                ChannelCredentialSummaryAdjuster(factors: ["online": 0.72]),
                CredentialSummaryUpdatedAtOffsetAdjuster(weight: 1.87),
                PercentCredentialSummaryAdjuster(percent: -23.6),
                CapCredentialSummaryAdjuster(cap: 46505.0),
                TieredCredentialSummaryAdjuster(bounds: [3729.0, 5121.0], rates: [1.0, 1.02]),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 54115.8
        )
    }
}
