import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the census tier calculation.
    protocol CensusTierStep {
        func describe() -> String
        func adjust(_ item: CensusTier, value: Double) -> Double
    }

    final class FlaggedCensusTierAdjuster: CensusTierStep {
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

        func adjust(_ item: CensusTier, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingCensusTierAdjuster: CensusTierStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CensusTier, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CensusTierWindowDaysOffsetAdjuster: CensusTierStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: CensusTier, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    /// Runs the census tier steps in order and keeps a trace of each.
    final class CensusTierEngine {
        var steps: [any CensusTierStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CensusTierStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CensusTier) -> Double {
            var current = item.adjustedValue()
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

        func evaluateAll(_ items: [CensusTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCensusTierEngine(_ flags: Kit.Flags.Registry) -> CensusTierEngine {
        return CensusTierEngine(
            steps: [
                FlaggedCensusTierAdjuster(flags: flags, flag: "census-tier-global", percent: 5.0),
                RoundingCensusTierAdjuster(step: 0.1),
                CensusTierWindowDaysOffsetAdjuster(weight: 1.83),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 82435.8
        )
    }
}
