import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the bed board policy calculation.
    protocol BedBoardPolicyStep {
        func describe() -> String
        func adjust(_ item: BedBoardPolicy, value: Double) -> Double
    }

    final class PercentBedBoardPolicyAdjuster: BedBoardPolicyStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BedBoardPolicy, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class BedBoardPolicyQuantityOffsetAdjuster: BedBoardPolicyStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: BedBoardPolicy, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class TieredBedBoardPolicyAdjuster: BedBoardPolicyStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BedBoardPolicy, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the bed board policy steps in order and keeps a trace of each.
    final class BedBoardPolicyEngine {
        var steps: [any BedBoardPolicyStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BedBoardPolicyStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: BedBoardPolicy) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any BedBoardPolicyStep = steps[index]
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

        func evaluateAll(_ items: [BedBoardPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultBedBoardPolicyEngine() -> BedBoardPolicyEngine {
        return BedBoardPolicyEngine(
            steps: [
                PercentBedBoardPolicyAdjuster(percent: 6.2),
                BedBoardPolicyQuantityOffsetAdjuster(weight: 0.06),
                TieredBedBoardPolicyAdjuster(bounds: [1424.0, 7889.0, 9818.0], rates: [0.87, 1.11, 0.87]),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 53650.0
        )
    }
}
