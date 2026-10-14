import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the transfer override calculation.
    protocol TransferOverrideStep {
        func describe() -> String
        func adjust(_ item: TransferOverride, value: Double) -> Double
    }

    final class MinimumTransferOverrideAdjuster: TransferOverrideStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TransferOverride, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapTransferOverrideAdjuster: TransferOverrideStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TransferOverride, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedTransferOverrideAdjuster: TransferOverrideStep {
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

        func adjust(_ item: TransferOverride, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TransferOverrideMarginOffsetAdjuster: TransferOverrideStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus margin times \(weight)"
        }

        func adjust(_ item: TransferOverride, value: Double) -> Double {
            return value + item.margin * weight
        }
    }

    final class FacilityTransferOverrideAdjuster: TransferOverrideStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: TransferOverride, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the transfer override steps in order and keeps a trace of each.
    final class TransferOverrideEngine {
        var steps: [any TransferOverrideStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TransferOverrideStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: TransferOverride) -> Double {
            var current = item.effectiveValue()
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

        func evaluateAll(_ items: [TransferOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultTransferOverrideEngine(_ flags: Kit.Flags.Registry) -> TransferOverrideEngine {
        return TransferOverrideEngine(
            steps: [
                MinimumTransferOverrideAdjuster(minimum: 20.2),
                CapTransferOverrideAdjuster(cap: 34163.0),
                FlaggedTransferOverrideAdjuster(flags: flags, flag: "transfer-override-scheduled", percent: -8.2),
                TransferOverrideMarginOffsetAdjuster(weight: 0.17),
                FacilityTransferOverrideAdjuster(factors: ["online": 0.78]),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 38145.8
        )
    }
}
