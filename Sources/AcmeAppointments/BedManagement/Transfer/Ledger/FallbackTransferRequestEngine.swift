import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the fallback transfer request calculation.
    protocol FallbackTransferRequestFactor {
        func describe() -> String
        func adjust(_ item: FallbackTransferRequest, value: Double) -> Double
    }

    final class RoundingFallbackTransferRequestAdjuster: FallbackTransferRequestFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackTransferRequest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FallbackTransferRequestVisitMinutesOffsetAdjuster: FallbackTransferRequestFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus visit minutes times \(weight)"
        }

        func adjust(_ item: FallbackTransferRequest, value: Double) -> Double {
            return value + Double(item.visitMinutes) * weight
        }
    }

    final class FlaggedFallbackTransferRequestAdjuster: FallbackTransferRequestFactor {
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

        func adjust(_ item: FallbackTransferRequest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredFallbackTransferRequestAdjuster: FallbackTransferRequestFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackTransferRequest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the fallback transfer request steps in order and keeps a trace of each.
    final class FallbackTransferRequestEngine {
        var steps: [any FallbackTransferRequestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackTransferRequestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FallbackTransferRequest) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackTransferRequestFactor = steps[index]
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

        func evaluateAll(_ items: [FallbackTransferRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFallbackTransferRequestEngine(_ flags: Kit.Flags.Registry) -> FallbackTransferRequestEngine {
        return FallbackTransferRequestEngine(
            steps: [
                RoundingFallbackTransferRequestAdjuster(step: 0.25),
                FallbackTransferRequestVisitMinutesOffsetAdjuster(weight: 1.19),
                FlaggedFallbackTransferRequestAdjuster(
                    flags: flags,
                    flag: "fallback-transfer-request-scheduled",
                    percent: -3.4
                ),
                TieredFallbackTransferRequestAdjuster(bounds: [335.0, 3154.0, 8687.0], rates: [1.16, 0.85, 0.97]),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 45345.9
        )
    }
}
