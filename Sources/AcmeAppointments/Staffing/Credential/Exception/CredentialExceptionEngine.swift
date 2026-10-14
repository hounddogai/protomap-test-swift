import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the credential exception calculation.
    protocol CredentialExceptionAdjuster {
        func describe() -> String
        func adjust(_ item: CredentialException, value: Double) -> Double
    }

    final class CapCredentialExceptionAdjuster: CredentialExceptionAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CredentialException, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredCredentialExceptionAdjuster: CredentialExceptionAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CredentialException, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FacilityCredentialExceptionAdjuster: CredentialExceptionAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: CredentialException, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentCredentialExceptionAdjuster: CredentialExceptionAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CredentialException, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the credential exception steps in order and keeps a trace of each.
    final class CredentialExceptionEngine {
        var steps: [any CredentialExceptionAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CredentialExceptionAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CredentialException) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any CredentialExceptionAdjuster = steps[index]
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

        func evaluateAll(_ items: [CredentialException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCredentialExceptionEngine() -> CredentialExceptionEngine {
        return CredentialExceptionEngine(
            steps: [
                CapCredentialExceptionAdjuster(cap: 17698.0),
                TieredCredentialExceptionAdjuster(bounds: [3629.0, 6470.0], rates: [0.91, 1.04]),
                FacilityCredentialExceptionAdjuster(factors: ["central": 1.09, "north": 1.27]),
                PercentCredentialExceptionAdjuster(percent: -8.1),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 38772.4
        )
    }
}
