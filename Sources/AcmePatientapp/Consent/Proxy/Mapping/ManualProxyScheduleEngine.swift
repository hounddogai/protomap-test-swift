import AcmePlatform
import Foundation

extension Consent {
    /// One step of the manual proxy schedule calculation.
    protocol ManualProxyScheduleFactor {
        func describe() -> String
        func adjust(_ item: ManualProxySchedule, value: Double) -> Double
    }

    final class TitleManualProxyScheduleAdjuster: ManualProxyScheduleFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: ManualProxySchedule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentManualProxyScheduleAdjuster: ManualProxyScheduleFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualProxySchedule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumManualProxyScheduleAdjuster: ManualProxyScheduleFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualProxySchedule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the manual proxy schedule steps in order and keeps a trace of each.
    final class ManualProxyScheduleEngine {
        var steps: [any ManualProxyScheduleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualProxyScheduleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ManualProxySchedule) -> Double {
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

        func evaluateAll(_ items: [ManualProxySchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultManualProxyScheduleEngine() -> ManualProxyScheduleEngine {
        return ManualProxyScheduleEngine(
            steps: [
                TitleManualProxyScheduleAdjuster(factors: ["central": 1.32, "east": 0.76, "online": 0.95]),
                PercentManualProxyScheduleAdjuster(percent: -5.0),
                MinimumManualProxyScheduleAdjuster(minimum: 46.8),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 71948.4
        )
    }
}
