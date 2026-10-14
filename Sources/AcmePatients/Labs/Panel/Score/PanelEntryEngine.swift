import AcmePlatform
import Foundation

extension Labs {
    /// One step of the panel entry calculation.
    protocol PanelEntryFactor {
        func describe() -> String
        func adjust(_ item: PanelEntry, value: Double) -> Double
    }

    final class CapPanelEntryAdjuster: PanelEntryFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PanelEntry, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredPanelEntryAdjuster: PanelEntryFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PanelEntry, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentPanelEntryAdjuster: PanelEntryFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PanelEntry, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SourcePanelEntryAdjuster: PanelEntryFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: PanelEntry, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumPanelEntryAdjuster: PanelEntryFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PanelEntry, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedPanelEntryAdjuster: PanelEntryFactor {
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

        func adjust(_ item: PanelEntry, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the panel entry steps in order and keeps a trace of each.
    final class PanelEntryEngine {
        var steps: [any PanelEntryFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PanelEntryFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PanelEntry) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any PanelEntryFactor = steps[index]
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

        func evaluateAll(_ items: [PanelEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPanelEntryEngine(_ flags: Kit.Flags.Registry) -> PanelEntryEngine {
        return PanelEntryEngine(
            steps: [
                CapPanelEntryAdjuster(cap: 16384.0),
                TieredPanelEntryAdjuster(bounds: [837.0, 1227.0, 8814.0], rates: [0.89, 0.95, 1.1]),
                PercentPanelEntryAdjuster(percent: -14.1),
                SourcePanelEntryAdjuster(factors: ["north": 0.86, "west": 0.74]),
                MinimumPanelEntryAdjuster(minimum: 20.6),
                FlaggedPanelEntryAdjuster(flags: flags, flag: "panel-entry-legacy", percent: 6.4),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 75402.3
        )
    }
}
