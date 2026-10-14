import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the primary worklist digest calculation.
    protocol PrimaryWorklistDigestAdjuster {
        func describe() -> String
        func adjust(_ item: PrimaryWorklistDigest, value: Double) -> Double
    }

    final class PrimaryWorklistDigestFloorValueOffsetAdjuster: PrimaryWorklistDigestAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus floor value times \(weight)"
        }

        func adjust(_ item: PrimaryWorklistDigest, value: Double) -> Double {
            return value + item.floorValue * weight
        }
    }

    final class CapPrimaryWorklistDigestAdjuster: PrimaryWorklistDigestAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryWorklistDigest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentPrimaryWorklistDigestAdjuster: PrimaryWorklistDigestAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryWorklistDigest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the primary worklist digest steps in order and keeps a trace of each.
    final class PrimaryWorklistDigestEngine {
        var steps: [any PrimaryWorklistDigestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryWorklistDigestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PrimaryWorklistDigest) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimaryWorklistDigestAdjuster = steps[index]
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

        func evaluateAll(_ items: [PrimaryWorklistDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPrimaryWorklistDigestEngine() -> PrimaryWorklistDigestEngine {
        return PrimaryWorklistDigestEngine(
            steps: [
                PrimaryWorklistDigestFloorValueOffsetAdjuster(weight: 0.66),
                CapPrimaryWorklistDigestAdjuster(cap: 19117.0),
                PercentPrimaryWorklistDigestAdjuster(percent: 9.0),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 74459.4
        )
    }
}
