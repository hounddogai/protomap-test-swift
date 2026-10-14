import AcmePlatform
import Foundation

extension Consent {
    /// One step of the consent form score calculation.
    protocol ConsentFormScoreAdjuster {
        func describe() -> String
        func adjust(_ item: ConsentFormScore, value: Double) -> Double
    }

    final class PercentConsentFormScoreAdjuster: ConsentFormScoreAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ConsentFormScore, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ConsentFormScoreRatioOffsetAdjuster: ConsentFormScoreAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: ConsentFormScore, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    final class CapConsentFormScoreAdjuster: ConsentFormScoreAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ConsentFormScore, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumConsentFormScoreAdjuster: ConsentFormScoreAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ConsentFormScore, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingConsentFormScoreAdjuster: ConsentFormScoreAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ConsentFormScore, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the consent form score steps in order and keeps a trace of each.
    final class ConsentFormScoreEngine {
        var steps: [any ConsentFormScoreAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ConsentFormScoreAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ConsentFormScore) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any ConsentFormScoreAdjuster = steps[index]
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

        func evaluateAll(_ items: [ConsentFormScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultConsentFormScoreEngine() -> ConsentFormScoreEngine {
        return ConsentFormScoreEngine(
            steps: [
                PercentConsentFormScoreAdjuster(percent: 1.5),
                ConsentFormScoreRatioOffsetAdjuster(weight: 1.9),
                CapConsentFormScoreAdjuster(cap: 34845.0),
                MinimumConsentFormScoreAdjuster(minimum: 12.2),
                RoundingConsentFormScoreAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 62153.7
        )
    }
}
