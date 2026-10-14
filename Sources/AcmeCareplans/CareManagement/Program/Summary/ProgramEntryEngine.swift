import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the program entry calculation.
    protocol ProgramEntryAdjuster {
        func describe() -> String
        func adjust(_ item: ProgramEntry, value: Double) -> Double
    }

    final class PercentProgramEntryAdjuster: ProgramEntryAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ProgramEntry, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapProgramEntryAdjuster: ProgramEntryAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ProgramEntry, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RegionProgramEntryAdjuster: ProgramEntryAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: ProgramEntry, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredProgramEntryAdjuster: ProgramEntryAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ProgramEntry, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumProgramEntryAdjuster: ProgramEntryAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ProgramEntry, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the program entry steps in order and keeps a trace of each.
    final class ProgramEntryEngine {
        var steps: [any ProgramEntryAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ProgramEntryAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ProgramEntry) -> Double {
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

        func evaluateAll(_ items: [ProgramEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultProgramEntryEngine() -> ProgramEntryEngine {
        return ProgramEntryEngine(
            steps: [
                PercentProgramEntryAdjuster(percent: 19.3),
                CapProgramEntryAdjuster(cap: 37241.0),
                RegionProgramEntryAdjuster(factors: ["east": 1.11]),
                TieredProgramEntryAdjuster(bounds: [91.0, 377.0, 1146.0, 9539.0], rates: [0.91, 0.89, 1.15, 1.08]),
                MinimumProgramEntryAdjuster(minimum: 16.5),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 3848.5
        )
    }
}
