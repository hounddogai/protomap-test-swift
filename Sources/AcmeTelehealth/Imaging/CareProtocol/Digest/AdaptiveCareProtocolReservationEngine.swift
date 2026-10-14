import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the adaptive care protocol reservation calculation.
    protocol AdaptiveCareProtocolReservationModifier {
        func describe() -> String
        func adjust(_ item: AdaptiveCareProtocolReservation, value: Double) -> Double
    }

    final class AdaptiveCareProtocolReservationSequenceOffsetAdjuster: AdaptiveCareProtocolReservationModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus sequence times \(weight)"
        }

        func adjust(_ item: AdaptiveCareProtocolReservation, value: Double) -> Double {
            return value + Double(item.sequence) * weight
        }
    }

    final class RoundingAdaptiveCareProtocolReservationAdjuster: AdaptiveCareProtocolReservationModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveCareProtocolReservation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredAdaptiveCareProtocolReservationAdjuster: AdaptiveCareProtocolReservationModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveCareProtocolReservation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the adaptive care protocol reservation steps in order and keeps a trace of each.
    final class AdaptiveCareProtocolReservationEngine {
        var steps: [any AdaptiveCareProtocolReservationModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveCareProtocolReservationModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AdaptiveCareProtocolReservation) -> Double {
            var current = item.adjustedVolume()
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

        func evaluateAll(_ items: [AdaptiveCareProtocolReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAdaptiveCareProtocolReservationEngine() -> AdaptiveCareProtocolReservationEngine {
        return AdaptiveCareProtocolReservationEngine(
            steps: [
                AdaptiveCareProtocolReservationSequenceOffsetAdjuster(weight: 0.37),
                RoundingAdaptiveCareProtocolReservationAdjuster(step: 0.5),
                TieredAdaptiveCareProtocolReservationAdjuster(
                    bounds: [2435.0, 2528.0, 5790.0],
                    rates: [1.17, 0.81, 1.17]
                ),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 69428.4
        )
    }
}
