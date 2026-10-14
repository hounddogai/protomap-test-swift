import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the bed board agreement calculation.
    protocol BedBoardAgreementFactor {
        func describe() -> String
        func adjust(_ item: BedBoardAgreement, value: Double) -> Double
    }

    final class MinimumBedBoardAgreementAdjuster: BedBoardAgreementFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BedBoardAgreement, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class BedBoardAgreementDurationMinutesOffsetAdjuster: BedBoardAgreementFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus duration minutes times \(weight)"
        }

        func adjust(_ item: BedBoardAgreement, value: Double) -> Double {
            return value + Double(item.durationMinutes) * weight
        }
    }

    final class PercentBedBoardAgreementAdjuster: BedBoardAgreementFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BedBoardAgreement, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedBedBoardAgreementAdjuster: BedBoardAgreementFactor {
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

        func adjust(_ item: BedBoardAgreement, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapBedBoardAgreementAdjuster: BedBoardAgreementFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BedBoardAgreement, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredBedBoardAgreementAdjuster: BedBoardAgreementFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BedBoardAgreement, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the bed board agreement steps in order and keeps a trace of each.
    final class BedBoardAgreementEngine {
        var steps: [any BedBoardAgreementFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BedBoardAgreementFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: BedBoardAgreement) -> Double {
            var current = item.adjustedLoad()
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

        func evaluateAll(_ items: [BedBoardAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultBedBoardAgreementEngine(_ flags: Kit.Flags.Registry) -> BedBoardAgreementEngine {
        return BedBoardAgreementEngine(
            steps: [
                MinimumBedBoardAgreementAdjuster(minimum: 21.8),
                BedBoardAgreementDurationMinutesOffsetAdjuster(weight: 0.65),
                PercentBedBoardAgreementAdjuster(percent: -8.7),
                FlaggedBedBoardAgreementAdjuster(flags: flags, flag: "bed-board-agreement-seasonal", percent: -6.9),
                CapBedBoardAgreementAdjuster(cap: 21177.0),
                TieredBedBoardAgreementAdjuster(bounds: [1196.0, 3600.0, 9352.0], rates: [0.85, 1.05, 1.06]),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 44775.9
        )
    }
}
