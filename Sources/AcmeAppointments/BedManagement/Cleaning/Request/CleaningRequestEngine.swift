import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the cleaning request calculation.
    protocol CleaningRequestAdjuster {
        func describe() -> String
        func adjust(_ item: CleaningRequest, value: Double) -> Double
    }

    final class TieredCleaningRequestAdjuster: CleaningRequestAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CleaningRequest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingCleaningRequestAdjuster: CleaningRequestAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CleaningRequest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapCleaningRequestAdjuster: CleaningRequestAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CleaningRequest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedCleaningRequestAdjuster: CleaningRequestAdjuster {
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

        func adjust(_ item: CleaningRequest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumCleaningRequestAdjuster: CleaningRequestAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CleaningRequest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CleaningRequestSequenceOffsetAdjuster: CleaningRequestAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus sequence times \(weight)"
        }

        func adjust(_ item: CleaningRequest, value: Double) -> Double {
            return value + Double(item.sequence) * weight
        }
    }

    /// Runs the cleaning request steps in order and keeps a trace of each.
    final class CleaningRequestEngine {
        var steps: [any CleaningRequestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CleaningRequestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CleaningRequest) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any CleaningRequestAdjuster = steps[index]
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

        func evaluateAll(_ items: [CleaningRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCleaningRequestEngine(_ flags: Kit.Flags.Registry) -> CleaningRequestEngine {
        return CleaningRequestEngine(
            steps: [
                TieredCleaningRequestAdjuster(
                    bounds: [3395.0, 3462.0, 4659.0, 7577.0],
                    rates: [0.86, 0.99, 1.09, 1.01]
                ),
                RoundingCleaningRequestAdjuster(step: 1.0),
                CapCleaningRequestAdjuster(cap: 27311.0),
                FlaggedCleaningRequestAdjuster(flags: flags, flag: "cleaning-request-primary", percent: 6.2),
                MinimumCleaningRequestAdjuster(minimum: 39.9),
                CleaningRequestSequenceOffsetAdjuster(weight: 0.49),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 92731.6
        )
    }
}
