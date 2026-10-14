import AcmePlatform
import Foundation

extension Consent {
    /// One step of the proxy reservation calculation.
    protocol ProxyReservationModifier {
        func describe() -> String
        func adjust(_ item: ProxyReservation, value: Double) -> Double
    }

    final class FlaggedProxyReservationAdjuster: ProxyReservationModifier {
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

        func adjust(_ item: ProxyReservation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingProxyReservationAdjuster: ProxyReservationModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ProxyReservation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredProxyReservationAdjuster: ProxyReservationModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ProxyReservation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the proxy reservation steps in order and keeps a trace of each.
    final class ProxyReservationEngine {
        var steps: [any ProxyReservationModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ProxyReservationModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ProxyReservation) -> Double {
            var current = item.netValue()
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

        func evaluateAll(_ items: [ProxyReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultProxyReservationEngine(_ flags: Kit.Flags.Registry) -> ProxyReservationEngine {
        return ProxyReservationEngine(
            steps: [
                FlaggedProxyReservationAdjuster(flags: flags, flag: "proxy-reservation-rolling", percent: 7.3),
                RoundingProxyReservationAdjuster(step: 0.5),
                TieredProxyReservationAdjuster(bounds: [1024.0, 2538.0, 6655.0], rates: [1.1, 0.99, 1.09]),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 74693.1
        )
    }
}
