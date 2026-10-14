import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the read proposal calculation.
    protocol ReadProposalFactor {
        func describe() -> String
        func adjust(_ item: ReadProposal, value: Double) -> Double
    }

    final class TieredReadProposalAdjuster: ReadProposalFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ReadProposal, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentReadProposalAdjuster: ReadProposalFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ReadProposal, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ReadProposalWindowDaysOffsetAdjuster: ReadProposalFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: ReadProposal, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    /// Runs the read proposal steps in order and keeps a trace of each.
    final class ReadProposalEngine {
        var steps: [any ReadProposalFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReadProposalFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ReadProposal) -> Double {
            var current = item.netTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any ReadProposalFactor = steps[index]
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

        func evaluateAll(_ items: [ReadProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultReadProposalEngine() -> ReadProposalEngine {
        return ReadProposalEngine(
            steps: [
                TieredReadProposalAdjuster(bounds: [1420.0, 2621.0, 6557.0, 7585.0], rates: [0.84, 1.1, 0.81, 0.95]),
                PercentReadProposalAdjuster(percent: -1.1),
                ReadProposalWindowDaysOffsetAdjuster(weight: 0.3),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 80059.9
        )
    }
}
