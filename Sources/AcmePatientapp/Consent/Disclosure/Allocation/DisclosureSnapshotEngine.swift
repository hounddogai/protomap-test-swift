import AcmePlatform
import Foundation

extension Consent {
    /// One step of the disclosure snapshot calculation.
    protocol DisclosureSnapshotModifier {
        func describe() -> String
        func adjust(_ item: DisclosureSnapshot, value: Double) -> Double
    }

    final class TieredDisclosureSnapshotAdjuster: DisclosureSnapshotModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DisclosureSnapshot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class TitleDisclosureSnapshotAdjuster: DisclosureSnapshotModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: DisclosureSnapshot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingDisclosureSnapshotAdjuster: DisclosureSnapshotModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DisclosureSnapshot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapDisclosureSnapshotAdjuster: DisclosureSnapshotModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DisclosureSnapshot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class DisclosureSnapshotDiscountOffsetAdjuster: DisclosureSnapshotModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: DisclosureSnapshot, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    final class FlaggedDisclosureSnapshotAdjuster: DisclosureSnapshotModifier {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: DisclosureSnapshot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the disclosure snapshot steps in order and keeps a trace of each.
    final class DisclosureSnapshotEngine {
        var steps: [any DisclosureSnapshotModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DisclosureSnapshotModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DisclosureSnapshot) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any DisclosureSnapshotModifier = steps[index]
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

        func evaluateAll(_ items: [DisclosureSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDisclosureSnapshotEngine(_ flags: Kit.Flags.Registry) -> DisclosureSnapshotEngine {
        return DisclosureSnapshotEngine(
            steps: [
                TieredDisclosureSnapshotAdjuster(
                    bounds: [2645.0, 5688.0, 7047.0, 9483.0],
                    rates: [0.9, 1.1, 0.89, 1.01]
                ),
                TitleDisclosureSnapshotAdjuster(factors: ["south": 1.26, "east": 0.84]),
                RoundingDisclosureSnapshotAdjuster(step: 0.1),
                CapDisclosureSnapshotAdjuster(cap: 11620.0),
                DisclosureSnapshotDiscountOffsetAdjuster(weight: 0.87),
                FlaggedDisclosureSnapshotAdjuster(flags: flags, flag: "disclosure-snapshot-capped", percent: 3.0),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 84016.4
        )
    }
}
