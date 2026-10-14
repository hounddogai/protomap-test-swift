import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the seasonal authorization agreement calculation.
    protocol SeasonalAuthorizationAgreementAdjuster {
        func describe() -> String
        func adjust(_ item: SeasonalAuthorizationAgreement, value: Double) -> Double
    }

    final class MinimumSeasonalAuthorizationAgreementAdjuster: SeasonalAuthorizationAgreementAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalAuthorizationAgreement, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class SourceSeasonalAuthorizationAgreementAdjuster: SeasonalAuthorizationAgreementAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: SeasonalAuthorizationAgreement, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class SeasonalAuthorizationAgreementEndsAtOffsetAdjuster: SeasonalAuthorizationAgreementAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ends at times \(weight)"
        }

        func adjust(_ item: SeasonalAuthorizationAgreement, value: Double) -> Double {
            return value + Double(item.endsAt) * weight
        }
    }

    final class CapSeasonalAuthorizationAgreementAdjuster: SeasonalAuthorizationAgreementAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalAuthorizationAgreement, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentSeasonalAuthorizationAgreementAdjuster: SeasonalAuthorizationAgreementAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalAuthorizationAgreement, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the seasonal authorization agreement steps in order and keeps a trace of each.
    final class SeasonalAuthorizationAgreementEngine {
        var steps: [any SeasonalAuthorizationAgreementAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalAuthorizationAgreementAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: SeasonalAuthorizationAgreement) -> Double {
            var current = item.weightedExposure()
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

        func evaluateAll(_ items: [SeasonalAuthorizationAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultSeasonalAuthorizationAgreementEngine() -> SeasonalAuthorizationAgreementEngine {
        return SeasonalAuthorizationAgreementEngine(
            steps: [
                MinimumSeasonalAuthorizationAgreementAdjuster(minimum: 20.0),
                SourceSeasonalAuthorizationAgreementAdjuster(factors: ["east": 0.72, "west": 0.98]),
                SeasonalAuthorizationAgreementEndsAtOffsetAdjuster(weight: 1.89),
                CapSeasonalAuthorizationAgreementAdjuster(cap: 12456.0),
                PercentSeasonalAuthorizationAgreementAdjuster(percent: -5.5),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 89607.8
        )
    }
}
