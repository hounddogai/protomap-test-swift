import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the authorization batch calculation.
    protocol AuthorizationBatchStep {
        func describe() -> String
        func adjust(_ item: AuthorizationBatch, value: Double) -> Double
    }

    final class PercentAuthorizationBatchAdjuster: AuthorizationBatchStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AuthorizationBatch, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class AuthorizationBatchFloorValueOffsetAdjuster: AuthorizationBatchStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus floor value times \(weight)"
        }

        func adjust(_ item: AuthorizationBatch, value: Double) -> Double {
            return value + item.floorValue * weight
        }
    }

    final class FlaggedAuthorizationBatchAdjuster: AuthorizationBatchStep {
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

        func adjust(_ item: AuthorizationBatch, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the authorization batch steps in order and keeps a trace of each.
    final class AuthorizationBatchEngine {
        var steps: [any AuthorizationBatchStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AuthorizationBatchStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AuthorizationBatch) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any AuthorizationBatchStep = steps[index]
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

        func evaluateAll(_ items: [AuthorizationBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAuthorizationBatchEngine(_ flags: Kit.Flags.Registry) -> AuthorizationBatchEngine {
        return AuthorizationBatchEngine(
            steps: [
                PercentAuthorizationBatchAdjuster(percent: -12.8),
                AuthorizationBatchFloorValueOffsetAdjuster(weight: 1.96),
                FlaggedAuthorizationBatchAdjuster(flags: flags, flag: "authorization-batch-adaptive", percent: -1.5),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 28332.8
        )
    }
}
