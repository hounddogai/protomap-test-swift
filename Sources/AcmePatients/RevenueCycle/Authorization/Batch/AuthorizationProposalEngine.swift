import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the authorization proposal calculation.
    protocol AuthorizationProposalFactor {
        func describe() -> String
        func adjust(_ item: AuthorizationProposal, value: Double) -> Double
    }

    final class AuthorizationProposalRatioOffsetAdjuster: AuthorizationProposalFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: AuthorizationProposal, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    final class TieredAuthorizationProposalAdjuster: AuthorizationProposalFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AuthorizationProposal, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentAuthorizationProposalAdjuster: AuthorizationProposalFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AuthorizationProposal, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the authorization proposal steps in order and keeps a trace of each.
    final class AuthorizationProposalEngine {
        var steps: [any AuthorizationProposalFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AuthorizationProposalFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AuthorizationProposal) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any AuthorizationProposalFactor = steps[index]
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

        func evaluateAll(_ items: [AuthorizationProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAuthorizationProposalEngine() -> AuthorizationProposalEngine {
        return AuthorizationProposalEngine(
            steps: [
                AuthorizationProposalRatioOffsetAdjuster(weight: 0.78),
                TieredAuthorizationProposalAdjuster(bounds: [5861.0, 6958.0, 7269.0], rates: [1.19, 1.05, 0.93]),
                PercentAuthorizationProposalAdjuster(percent: -3.6),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 12160.2
        )
    }
}
