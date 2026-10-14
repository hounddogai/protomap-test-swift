import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the transfer notice calculation.
    protocol TransferNoticeStep {
        func describe() -> String
        func adjust(_ item: TransferNotice, value: Double) -> Double
    }

    final class MinimumTransferNoticeAdjuster: TransferNoticeStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TransferNotice, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredTransferNoticeAdjuster: TransferNoticeStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TransferNotice, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingTransferNoticeAdjuster: TransferNoticeStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TransferNotice, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentTransferNoticeAdjuster: TransferNoticeStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TransferNotice, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapTransferNoticeAdjuster: TransferNoticeStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TransferNotice, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the transfer notice steps in order and keeps a trace of each.
    final class TransferNoticeEngine {
        var steps: [any TransferNoticeStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TransferNoticeStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: TransferNotice) -> Double {
            var current = item.projectedLoad()
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

        func evaluateAll(_ items: [TransferNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultTransferNoticeEngine() -> TransferNoticeEngine {
        return TransferNoticeEngine(
            steps: [
                MinimumTransferNoticeAdjuster(minimum: 42.2),
                TieredTransferNoticeAdjuster(bounds: [1089.0, 3674.0, 4366.0, 8874.0], rates: [1.03, 1.0, 1.12, 1.03]),
                RoundingTransferNoticeAdjuster(step: 0.5),
                PercentTransferNoticeAdjuster(percent: 11.3),
                CapTransferNoticeAdjuster(cap: 11612.0),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 92671.2
        )
    }
}
