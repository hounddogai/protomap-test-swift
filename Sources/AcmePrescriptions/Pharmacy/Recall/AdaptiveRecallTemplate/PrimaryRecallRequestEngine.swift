import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the primary recall request calculation.
    protocol PrimaryRecallRequestStep {
        func describe() -> String
        func adjust(_ item: PrimaryRecallRequest, value: Double) -> Double
    }

    final class PercentPrimaryRecallRequestAdjuster: PrimaryRecallRequestStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryRecallRequest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapPrimaryRecallRequestAdjuster: PrimaryRecallRequestStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryRecallRequest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingPrimaryRecallRequestAdjuster: PrimaryRecallRequestStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryRecallRequest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the primary recall request steps in order and keeps a trace of each.
    final class PrimaryRecallRequestEngine {
        var steps: [any PrimaryRecallRequestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryRecallRequestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PrimaryRecallRequest) -> Double {
            var current = item.projectedExposure()
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

        func evaluateAll(_ items: [PrimaryRecallRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPrimaryRecallRequestEngine() -> PrimaryRecallRequestEngine {
        return PrimaryRecallRequestEngine(
            steps: [
                PercentPrimaryRecallRequestAdjuster(percent: 18.6),
                CapPrimaryRecallRequestAdjuster(cap: 29947.0),
                RoundingPrimaryRecallRequestAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 45678.8
        )
    }
}
