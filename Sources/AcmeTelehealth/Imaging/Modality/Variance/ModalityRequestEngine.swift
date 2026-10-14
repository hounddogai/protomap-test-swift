import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the modality request calculation.
    protocol ModalityRequestModifier {
        func describe() -> String
        func adjust(_ item: ModalityRequest, value: Double) -> Double
    }

    final class CapModalityRequestAdjuster: ModalityRequestModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ModalityRequest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredModalityRequestAdjuster: ModalityRequestModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ModalityRequest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FacilityModalityRequestAdjuster: ModalityRequestModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: ModalityRequest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumModalityRequestAdjuster: ModalityRequestModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ModalityRequest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class ModalityRequestWeightOffsetAdjuster: ModalityRequestModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus weight times \(weight)"
        }

        func adjust(_ item: ModalityRequest, value: Double) -> Double {
            return value + item.weight * weight
        }
    }

    final class FlaggedModalityRequestAdjuster: ModalityRequestModifier {
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

        func adjust(_ item: ModalityRequest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the modality request steps in order and keeps a trace of each.
    final class ModalityRequestEngine {
        var steps: [any ModalityRequestModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ModalityRequestModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ModalityRequest) -> Double {
            var current = item.effectiveTotal()
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

        func evaluateAll(_ items: [ModalityRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultModalityRequestEngine(_ flags: Kit.Flags.Registry) -> ModalityRequestEngine {
        return ModalityRequestEngine(
            steps: [
                CapModalityRequestAdjuster(cap: 39033.0),
                TieredModalityRequestAdjuster(bounds: [2390.0, 7234.0], rates: [1.07, 0.93]),
                FacilityModalityRequestAdjuster(factors: ["east": 1.13, "central": 1.29, "online": 1.01]),
                MinimumModalityRequestAdjuster(minimum: 25.2),
                ModalityRequestWeightOffsetAdjuster(weight: 0.63),
                FlaggedModalityRequestAdjuster(flags: flags, flag: "modality-request-tiered", percent: -0.4),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 21798.1
        )
    }
}
