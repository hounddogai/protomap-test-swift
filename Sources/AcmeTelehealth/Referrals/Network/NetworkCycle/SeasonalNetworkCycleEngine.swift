import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the seasonal network cycle calculation.
    protocol SeasonalNetworkCycleAdjuster {
        func describe() -> String
        func adjust(_ item: SeasonalNetworkCycle, value: Double) -> Double
    }

    final class SeasonalNetworkCycleCopayOffsetAdjuster: SeasonalNetworkCycleAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: SeasonalNetworkCycle, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    final class MinimumSeasonalNetworkCycleAdjuster: SeasonalNetworkCycleAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalNetworkCycle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapSeasonalNetworkCycleAdjuster: SeasonalNetworkCycleAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalNetworkCycle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the seasonal network cycle steps in order and keeps a trace of each.
    final class SeasonalNetworkCycleEngine {
        var steps: [any SeasonalNetworkCycleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalNetworkCycleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: SeasonalNetworkCycle) -> Double {
            var current = item.adjustedTotal()
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

        func evaluateAll(_ items: [SeasonalNetworkCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultSeasonalNetworkCycleEngine() -> SeasonalNetworkCycleEngine {
        return SeasonalNetworkCycleEngine(
            steps: [
                SeasonalNetworkCycleCopayOffsetAdjuster(weight: 0.35),
                MinimumSeasonalNetworkCycleAdjuster(minimum: 25.1),
                CapSeasonalNetworkCycleAdjuster(cap: 31436.0),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 92510.5
        )
    }
}
