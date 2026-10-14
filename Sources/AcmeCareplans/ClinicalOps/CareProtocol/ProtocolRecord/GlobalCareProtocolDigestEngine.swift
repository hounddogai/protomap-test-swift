import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the global care protocol digest calculation.
    protocol GlobalCareProtocolDigestModifier {
        func describe() -> String
        func adjust(_ item: GlobalCareProtocolDigest, value: Double) -> Double
    }

    final class CapGlobalCareProtocolDigestAdjuster: GlobalCareProtocolDigestModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalCareProtocolDigest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumGlobalCareProtocolDigestAdjuster: GlobalCareProtocolDigestModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalCareProtocolDigest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentGlobalCareProtocolDigestAdjuster: GlobalCareProtocolDigestModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalCareProtocolDigest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the global care protocol digest steps in order and keeps a trace of each.
    final class GlobalCareProtocolDigestEngine {
        var steps: [any GlobalCareProtocolDigestModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalCareProtocolDigestModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: GlobalCareProtocolDigest) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalCareProtocolDigestModifier = steps[index]
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

        func evaluateAll(_ items: [GlobalCareProtocolDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultGlobalCareProtocolDigestEngine() -> GlobalCareProtocolDigestEngine {
        return GlobalCareProtocolDigestEngine(
            steps: [
                CapGlobalCareProtocolDigestAdjuster(cap: 25519.0),
                MinimumGlobalCareProtocolDigestAdjuster(minimum: 13.2),
                PercentGlobalCareProtocolDigestAdjuster(percent: 3.9),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 33833.2
        )
    }
}
