import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the outreach snapshot calculation.
    protocol OutreachSnapshotFactor {
        func describe() -> String
        func adjust(_ item: OutreachSnapshot, value: Double) -> Double
    }

    final class OutreachSnapshotSequenceOffsetAdjuster: OutreachSnapshotFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus sequence times \(weight)"
        }

        func adjust(_ item: OutreachSnapshot, value: Double) -> Double {
            return value + Double(item.sequence) * weight
        }
    }

    final class RoundingOutreachSnapshotAdjuster: OutreachSnapshotFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: OutreachSnapshot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentOutreachSnapshotAdjuster: OutreachSnapshotFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: OutreachSnapshot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumOutreachSnapshotAdjuster: OutreachSnapshotFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: OutreachSnapshot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapOutreachSnapshotAdjuster: OutreachSnapshotFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: OutreachSnapshot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredOutreachSnapshotAdjuster: OutreachSnapshotFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: OutreachSnapshot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the outreach snapshot steps in order and keeps a trace of each.
    final class OutreachSnapshotEngine {
        var steps: [any OutreachSnapshotFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OutreachSnapshotFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: OutreachSnapshot) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any OutreachSnapshotFactor = steps[index]
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

        func evaluateAll(_ items: [OutreachSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultOutreachSnapshotEngine() -> OutreachSnapshotEngine {
        return OutreachSnapshotEngine(
            steps: [
                OutreachSnapshotSequenceOffsetAdjuster(weight: 1.01),
                RoundingOutreachSnapshotAdjuster(step: 0.1),
                PercentOutreachSnapshotAdjuster(percent: 17.3),
                MinimumOutreachSnapshotAdjuster(minimum: 16.5),
                CapOutreachSnapshotAdjuster(cap: 8183.0),
                TieredOutreachSnapshotAdjuster(
                    bounds: [2893.0, 5120.0, 7400.0, 8779.0],
                    rates: [0.87, 1.2, 0.93, 1.14]
                ),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 82751.7
        )
    }
}
