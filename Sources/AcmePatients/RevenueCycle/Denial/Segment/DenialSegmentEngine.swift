import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the denial segment calculation.
    protocol DenialSegmentFactor {
        func describe() -> String
        func adjust(_ item: DenialSegment, value: Double) -> Double
    }

    final class CapDenialSegmentAdjuster: DenialSegmentFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DenialSegment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LocaleDenialSegmentAdjuster: DenialSegmentFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: DenialSegment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentDenialSegmentAdjuster: DenialSegmentFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DenialSegment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the denial segment steps in order and keeps a trace of each.
    final class DenialSegmentEngine {
        var steps: [any DenialSegmentFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DenialSegmentFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DenialSegment) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any DenialSegmentFactor = steps[index]
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

        func evaluateAll(_ items: [DenialSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDenialSegmentEngine() -> DenialSegmentEngine {
        return DenialSegmentEngine(
            steps: [
                CapDenialSegmentAdjuster(cap: 45088.0),
                LocaleDenialSegmentAdjuster(factors: ["south": 1.19, "west": 0.83]),
                PercentDenialSegmentAdjuster(percent: -14.9),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 76379.8
        )
    }
}
