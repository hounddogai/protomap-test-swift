import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the legacy care protocol entry calculation.
    protocol LegacyCareProtocolEntryFactor {
        func describe() -> String
        func adjust(_ item: LegacyCareProtocolEntry, value: Double) -> Double
    }

    final class LegacyCareProtocolEntryLimitOffsetAdjuster: LegacyCareProtocolEntryFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus limit times \(weight)"
        }

        func adjust(_ item: LegacyCareProtocolEntry, value: Double) -> Double {
            return value + Double(item.limit) * weight
        }
    }

    final class CapLegacyCareProtocolEntryAdjuster: LegacyCareProtocolEntryFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacyCareProtocolEntry, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumLegacyCareProtocolEntryAdjuster: LegacyCareProtocolEntryFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyCareProtocolEntry, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the legacy care protocol entry steps in order and keeps a trace of each.
    final class LegacyCareProtocolEntryEngine {
        var steps: [any LegacyCareProtocolEntryFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyCareProtocolEntryFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LegacyCareProtocolEntry) -> Double {
            var current = item.adjustedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacyCareProtocolEntryFactor = steps[index]
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

        func evaluateAll(_ items: [LegacyCareProtocolEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLegacyCareProtocolEntryEngine() -> LegacyCareProtocolEntryEngine {
        return LegacyCareProtocolEntryEngine(
            steps: [
                LegacyCareProtocolEntryLimitOffsetAdjuster(weight: 0.39),
                CapLegacyCareProtocolEntryAdjuster(cap: 32538.0),
                MinimumLegacyCareProtocolEntryAdjuster(minimum: 45.6),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 91768.2
        )
    }
}
