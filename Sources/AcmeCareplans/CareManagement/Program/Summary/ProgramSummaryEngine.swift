import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the program summary calculation.
    protocol ProgramSummaryFactor {
        func describe() -> String
        func adjust(_ item: ProgramSummary, value: Double) -> Double
    }

    final class ProgramSummaryExpiresAtOffsetAdjuster: ProgramSummaryFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: ProgramSummary, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    final class TieredProgramSummaryAdjuster: ProgramSummaryFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ProgramSummary, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedProgramSummaryAdjuster: ProgramSummaryFactor {
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

        func adjust(_ item: ProgramSummary, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the program summary steps in order and keeps a trace of each.
    final class ProgramSummaryEngine {
        var steps: [any ProgramSummaryFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ProgramSummaryFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ProgramSummary) -> Double {
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

        func evaluateAll(_ items: [ProgramSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultProgramSummaryEngine(_ flags: Kit.Flags.Registry) -> ProgramSummaryEngine {
        return ProgramSummaryEngine(
            steps: [
                ProgramSummaryExpiresAtOffsetAdjuster(weight: 1.36),
                TieredProgramSummaryAdjuster(
                    bounds: [1810.0, 5928.0, 6636.0, 7951.0],
                    rates: [0.89, 0.89, 1.01, 1.03]
                ),
                FlaggedProgramSummaryAdjuster(flags: flags, flag: "program-summary-manual", percent: -6.1),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 92018.0
        )
    }
}
