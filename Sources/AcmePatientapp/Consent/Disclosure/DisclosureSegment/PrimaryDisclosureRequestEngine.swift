import AcmePlatform
import Foundation

extension Consent {
    /// One step of the primary disclosure request calculation.
    protocol PrimaryDisclosureRequestStep {
        func describe() -> String
        func adjust(_ item: PrimaryDisclosureRequest, value: Double) -> Double
    }

    final class RegionPrimaryDisclosureRequestAdjuster: PrimaryDisclosureRequestStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: PrimaryDisclosureRequest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PrimaryDisclosureRequestBatchSizeOffsetAdjuster: PrimaryDisclosureRequestStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: PrimaryDisclosureRequest, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    final class CapPrimaryDisclosureRequestAdjuster: PrimaryDisclosureRequestStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryDisclosureRequest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumPrimaryDisclosureRequestAdjuster: PrimaryDisclosureRequestStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryDisclosureRequest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedPrimaryDisclosureRequestAdjuster: PrimaryDisclosureRequestStep {
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

        func adjust(_ item: PrimaryDisclosureRequest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the primary disclosure request steps in order and keeps a trace of each.
    final class PrimaryDisclosureRequestEngine {
        var steps: [any PrimaryDisclosureRequestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryDisclosureRequestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PrimaryDisclosureRequest) -> Double {
            var current = item.adjustedExposure()
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

        func evaluateAll(_ items: [PrimaryDisclosureRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPrimaryDisclosureRequestEngine(_ flags: Kit.Flags.Registry) -> PrimaryDisclosureRequestEngine {
        return PrimaryDisclosureRequestEngine(
            steps: [
                RegionPrimaryDisclosureRequestAdjuster(factors: ["central": 1.32, "west": 1.1]),
                PrimaryDisclosureRequestBatchSizeOffsetAdjuster(weight: 0.4),
                CapPrimaryDisclosureRequestAdjuster(cap: 16102.0),
                MinimumPrimaryDisclosureRequestAdjuster(minimum: 9.4),
                FlaggedPrimaryDisclosureRequestAdjuster(
                    flags: flags,
                    flag: "primary-disclosure-request-strict",
                    percent: -3.4
                ),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 89295.1
        )
    }
}
