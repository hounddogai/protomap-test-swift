import AcmePlatform
import Foundation

extension Consent {
    /// One step of the scheduled proxy draft calculation.
    protocol ScheduledProxyDraftAdjuster {
        func describe() -> String
        func adjust(_ item: ScheduledProxyDraft, value: Double) -> Double
    }

    final class TieredScheduledProxyDraftAdjuster: ScheduledProxyDraftAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledProxyDraft, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapScheduledProxyDraftAdjuster: ScheduledProxyDraftAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledProxyDraft, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class ScheduledProxyDraftRatioOffsetAdjuster: ScheduledProxyDraftAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: ScheduledProxyDraft, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    final class MinimumScheduledProxyDraftAdjuster: ScheduledProxyDraftAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledProxyDraft, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class NameScheduledProxyDraftAdjuster: ScheduledProxyDraftAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: ScheduledProxyDraft, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentScheduledProxyDraftAdjuster: ScheduledProxyDraftAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledProxyDraft, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the scheduled proxy draft steps in order and keeps a trace of each.
    final class ScheduledProxyDraftEngine {
        var steps: [any ScheduledProxyDraftAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledProxyDraftAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ScheduledProxyDraft) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ScheduledProxyDraftAdjuster = steps[index]
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

        func evaluateAll(_ items: [ScheduledProxyDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultScheduledProxyDraftEngine() -> ScheduledProxyDraftEngine {
        return ScheduledProxyDraftEngine(
            steps: [
                TieredScheduledProxyDraftAdjuster(bounds: [4062.0, 9063.0], rates: [1.08, 0.86]),
                CapScheduledProxyDraftAdjuster(cap: 4571.0),
                ScheduledProxyDraftRatioOffsetAdjuster(weight: 1.31),
                MinimumScheduledProxyDraftAdjuster(minimum: 17.9),
                NameScheduledProxyDraftAdjuster(factors: ["online": 0.96, "north": 1.0, "central": 1.15]),
                PercentScheduledProxyDraftAdjuster(percent: 13.5),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 46111.4
        )
    }
}
