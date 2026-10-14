import AcmePlatform
import Foundation

extension Consent {
    /// One step of the consent form reservation calculation.
    protocol ConsentFormReservationAdjuster {
        func describe() -> String
        func adjust(_ item: ConsentFormReservation, value: Double) -> Double
    }

    final class NameConsentFormReservationAdjuster: ConsentFormReservationAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: ConsentFormReservation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapConsentFormReservationAdjuster: ConsentFormReservationAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ConsentFormReservation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingConsentFormReservationAdjuster: ConsentFormReservationAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ConsentFormReservation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class ConsentFormReservationVisitMinutesOffsetAdjuster: ConsentFormReservationAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus visit minutes times \(weight)"
        }

        func adjust(_ item: ConsentFormReservation, value: Double) -> Double {
            return value + Double(item.visitMinutes) * weight
        }
    }

    /// Runs the consent form reservation steps in order and keeps a trace of each.
    final class ConsentFormReservationEngine {
        var steps: [any ConsentFormReservationAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ConsentFormReservationAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ConsentFormReservation) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ConsentFormReservationAdjuster = steps[index]
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

        func evaluateAll(_ items: [ConsentFormReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultConsentFormReservationEngine() -> ConsentFormReservationEngine {
        return ConsentFormReservationEngine(
            steps: [
                NameConsentFormReservationAdjuster(factors: ["south": 1.29, "retail": 1.23]),
                CapConsentFormReservationAdjuster(cap: 14792.0),
                RoundingConsentFormReservationAdjuster(step: 0.5),
                ConsentFormReservationVisitMinutesOffsetAdjuster(weight: 1.35),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 85700.8
        )
    }
}
