import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the network group calculation.
    protocol NetworkGroupModifier {
        func describe() -> String
        func adjust(_ item: NetworkGroup, value: Double) -> Double
    }

    final class RoundingNetworkGroupAdjuster: NetworkGroupModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: NetworkGroup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class NetworkGroupMaximumOffsetAdjuster: NetworkGroupModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus maximum times \(weight)"
        }

        func adjust(_ item: NetworkGroup, value: Double) -> Double {
            return value + item.maximum * weight
        }
    }

    final class CapNetworkGroupAdjuster: NetworkGroupModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: NetworkGroup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the network group steps in order and keeps a trace of each.
    final class NetworkGroupEngine {
        var steps: [any NetworkGroupModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any NetworkGroupModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: NetworkGroup) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any NetworkGroupModifier = steps[index]
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

        func evaluateAll(_ items: [NetworkGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultNetworkGroupEngine() -> NetworkGroupEngine {
        return NetworkGroupEngine(
            steps: [
                RoundingNetworkGroupAdjuster(step: 0.05),
                NetworkGroupMaximumOffsetAdjuster(weight: 0.35),
                CapNetworkGroupAdjuster(cap: 42157.0),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 67896.9
        )
    }
}
