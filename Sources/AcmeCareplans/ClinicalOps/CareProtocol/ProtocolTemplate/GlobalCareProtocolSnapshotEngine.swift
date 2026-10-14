import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the global care protocol snapshot calculation.
    protocol GlobalCareProtocolSnapshotStep {
        func describe() -> String
        func adjust(_ item: GlobalCareProtocolSnapshot, value: Double) -> Double
    }

    final class RoundingGlobalCareProtocolSnapshotAdjuster: GlobalCareProtocolSnapshotStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalCareProtocolSnapshot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentGlobalCareProtocolSnapshotAdjuster: GlobalCareProtocolSnapshotStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalCareProtocolSnapshot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapGlobalCareProtocolSnapshotAdjuster: GlobalCareProtocolSnapshotStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalCareProtocolSnapshot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the global care protocol snapshot steps in order and keeps a trace of each.
    final class GlobalCareProtocolSnapshotEngine {
        var steps: [any GlobalCareProtocolSnapshotStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalCareProtocolSnapshotStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: GlobalCareProtocolSnapshot) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalCareProtocolSnapshotStep = steps[index]
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

        func evaluateAll(_ items: [GlobalCareProtocolSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultGlobalCareProtocolSnapshotEngine() -> GlobalCareProtocolSnapshotEngine {
        return GlobalCareProtocolSnapshotEngine(
            steps: [
                RoundingGlobalCareProtocolSnapshotAdjuster(step: 0.05),
                PercentGlobalCareProtocolSnapshotAdjuster(percent: 19.5),
                CapGlobalCareProtocolSnapshotAdjuster(cap: 9438.0),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 44196.8
        )
    }
}
