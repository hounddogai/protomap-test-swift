import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the modality forecast calculation.
    protocol ModalityForecastStep {
        func describe() -> String
        func adjust(_ item: ModalityForecast, value: Double) -> Double
    }

    final class CapModalityForecastAdjuster: ModalityForecastStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ModalityForecast, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingModalityForecastAdjuster: ModalityForecastStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ModalityForecast, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentModalityForecastAdjuster: ModalityForecastStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ModalityForecast, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ModalityForecastFloorValueOffsetAdjuster: ModalityForecastStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus floor value times \(weight)"
        }

        func adjust(_ item: ModalityForecast, value: Double) -> Double {
            return value + item.floorValue * weight
        }
    }

    /// Runs the modality forecast steps in order and keeps a trace of each.
    final class ModalityForecastEngine {
        var steps: [any ModalityForecastStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ModalityForecastStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ModalityForecast) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any ModalityForecastStep = steps[index]
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

        func evaluateAll(_ items: [ModalityForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultModalityForecastEngine() -> ModalityForecastEngine {
        return ModalityForecastEngine(
            steps: [
                CapModalityForecastAdjuster(cap: 12776.0),
                RoundingModalityForecastAdjuster(step: 0.1),
                PercentModalityForecastAdjuster(percent: 0.4),
                ModalityForecastFloorValueOffsetAdjuster(weight: 0.28),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 59873.2
        )
    }
}
