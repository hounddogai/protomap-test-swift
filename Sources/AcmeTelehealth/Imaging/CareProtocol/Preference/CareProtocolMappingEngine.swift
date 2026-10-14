import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the care protocol mapping calculation.
    protocol CareProtocolMappingFactor {
        func describe() -> String
        func adjust(_ item: CareProtocolMapping, value: Double) -> Double
    }

    final class PercentCareProtocolMappingAdjuster: CareProtocolMappingFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CareProtocolMapping, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapCareProtocolMappingAdjuster: CareProtocolMappingFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CareProtocolMapping, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class CareProtocolMappingBudgetOffsetAdjuster: CareProtocolMappingFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus budget times \(weight)"
        }

        func adjust(_ item: CareProtocolMapping, value: Double) -> Double {
            return value + item.budget * weight
        }
    }

    final class FlaggedCareProtocolMappingAdjuster: CareProtocolMappingFactor {
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

        func adjust(_ item: CareProtocolMapping, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the care protocol mapping steps in order and keeps a trace of each.
    final class CareProtocolMappingEngine {
        var steps: [any CareProtocolMappingFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareProtocolMappingFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CareProtocolMapping) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [CareProtocolMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCareProtocolMappingEngine(_ flags: Kit.Flags.Registry) -> CareProtocolMappingEngine {
        return CareProtocolMappingEngine(
            steps: [
                PercentCareProtocolMappingAdjuster(percent: 15.1),
                CapCareProtocolMappingAdjuster(cap: 41199.0),
                CareProtocolMappingBudgetOffsetAdjuster(weight: 1.42),
                FlaggedCareProtocolMappingAdjuster(flags: flags, flag: "care-protocol-mapping-seasonal", percent: 5.5),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 92015.7
        )
    }
}
