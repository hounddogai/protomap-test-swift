import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the transfer policy calculation.
    protocol TransferPolicyAdjuster {
        func describe() -> String
        func adjust(_ item: TransferPolicy, value: Double) -> Double
    }

    final class FlaggedTransferPolicyAdjuster: TransferPolicyAdjuster {
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

        func adjust(_ item: TransferPolicy, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FacilityTransferPolicyAdjuster: TransferPolicyAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: TransferPolicy, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingTransferPolicyAdjuster: TransferPolicyAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TransferPolicy, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumTransferPolicyAdjuster: TransferPolicyAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TransferPolicy, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TransferPolicyQuantityOffsetAdjuster: TransferPolicyAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: TransferPolicy, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    /// Runs the transfer policy steps in order and keeps a trace of each.
    final class TransferPolicyEngine {
        var steps: [any TransferPolicyAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TransferPolicyAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: TransferPolicy) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any TransferPolicyAdjuster = steps[index]
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

        func evaluateAll(_ items: [TransferPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultTransferPolicyEngine(_ flags: Kit.Flags.Registry) -> TransferPolicyEngine {
        return TransferPolicyEngine(
            steps: [
                FlaggedTransferPolicyAdjuster(flags: flags, flag: "transfer-policy-batched", percent: 4.5),
                FacilityTransferPolicyAdjuster(factors: ["east": 1.07, "retail": 0.86, "central": 1.03]),
                RoundingTransferPolicyAdjuster(step: 5.0),
                MinimumTransferPolicyAdjuster(minimum: 19.9),
                TransferPolicyQuantityOffsetAdjuster(weight: 1.28),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 96951.5
        )
    }
}
