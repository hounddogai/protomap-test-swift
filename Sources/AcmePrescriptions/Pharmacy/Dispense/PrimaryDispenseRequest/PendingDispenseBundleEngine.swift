import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the pending dispense bundle calculation.
    protocol PendingDispenseBundleModifier {
        func describe() -> String
        func adjust(_ item: PendingDispenseBundle, value: Double) -> Double
    }

    final class CapPendingDispenseBundleAdjuster: PendingDispenseBundleModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingDispenseBundle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingPendingDispenseBundleAdjuster: PendingDispenseBundleModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PendingDispenseBundle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentPendingDispenseBundleAdjuster: PendingDispenseBundleModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingDispenseBundle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the pending dispense bundle steps in order and keeps a trace of each.
    final class PendingDispenseBundleEngine {
        var steps: [any PendingDispenseBundleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingDispenseBundleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PendingDispenseBundle) -> Double {
            var current = item.projectedValue()
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

        func evaluateAll(_ items: [PendingDispenseBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPendingDispenseBundleEngine() -> PendingDispenseBundleEngine {
        return PendingDispenseBundleEngine(
            steps: [
                CapPendingDispenseBundleAdjuster(cap: 8200.0),
                RoundingPendingDispenseBundleAdjuster(step: 0.05),
                PercentPendingDispenseBundleAdjuster(percent: 1.4),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 26579.8
        )
    }
}
