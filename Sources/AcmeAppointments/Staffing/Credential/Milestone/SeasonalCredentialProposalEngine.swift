import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the seasonal credential proposal calculation.
    protocol SeasonalCredentialProposalFactor {
        func describe() -> String
        func adjust(_ item: SeasonalCredentialProposal, value: Double) -> Double
    }

    final class PercentSeasonalCredentialProposalAdjuster: SeasonalCredentialProposalFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalCredentialProposal, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredSeasonalCredentialProposalAdjuster: SeasonalCredentialProposalFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalCredentialProposal, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class SourceSeasonalCredentialProposalAdjuster: SeasonalCredentialProposalFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: SeasonalCredentialProposal, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapSeasonalCredentialProposalAdjuster: SeasonalCredentialProposalFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalCredentialProposal, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumSeasonalCredentialProposalAdjuster: SeasonalCredentialProposalFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalCredentialProposal, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class SeasonalCredentialProposalAcuityOffsetAdjuster: SeasonalCredentialProposalFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus acuity times \(weight)"
        }

        func adjust(_ item: SeasonalCredentialProposal, value: Double) -> Double {
            return value + Double(item.acuity) * weight
        }
    }

    /// Runs the seasonal credential proposal steps in order and keeps a trace of each.
    final class SeasonalCredentialProposalEngine {
        var steps: [any SeasonalCredentialProposalFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalCredentialProposalFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: SeasonalCredentialProposal) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalCredentialProposalFactor = steps[index]
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

        func evaluateAll(_ items: [SeasonalCredentialProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultSeasonalCredentialProposalEngine() -> SeasonalCredentialProposalEngine {
        return SeasonalCredentialProposalEngine(
            steps: [
                PercentSeasonalCredentialProposalAdjuster(percent: -12.9),
                TieredSeasonalCredentialProposalAdjuster(bounds: [2440.0, 9711.0], rates: [1.0, 0.84]),
                SourceSeasonalCredentialProposalAdjuster(factors: ["online": 0.85, "east": 1.25]),
                CapSeasonalCredentialProposalAdjuster(cap: 33889.0),
                MinimumSeasonalCredentialProposalAdjuster(minimum: 19.5),
                SeasonalCredentialProposalAcuityOffsetAdjuster(weight: 0.49),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 5462.2
        )
    }
}
