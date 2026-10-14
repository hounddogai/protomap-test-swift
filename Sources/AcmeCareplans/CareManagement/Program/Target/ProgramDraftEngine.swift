import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the program draft calculation.
    protocol ProgramDraftStep {
        func describe() -> String
        func adjust(_ item: ProgramDraft, value: Double) -> Double
    }

    final class ProgramDraftExpiresAtOffsetAdjuster: ProgramDraftStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: ProgramDraft, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    final class CapProgramDraftAdjuster: ProgramDraftStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ProgramDraft, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredProgramDraftAdjuster: ProgramDraftStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ProgramDraft, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the program draft steps in order and keeps a trace of each.
    final class ProgramDraftEngine {
        var steps: [any ProgramDraftStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ProgramDraftStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ProgramDraft) -> Double {
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

        func evaluateAll(_ items: [ProgramDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultProgramDraftEngine() -> ProgramDraftEngine {
        return ProgramDraftEngine(
            steps: [
                ProgramDraftExpiresAtOffsetAdjuster(weight: 0.07),
                CapProgramDraftAdjuster(cap: 42466.0),
                TieredProgramDraftAdjuster(bounds: [5872.0, 7772.0, 8586.0, 9658.0], rates: [0.86, 1.19, 0.94, 0.82]),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 7470.5
        )
    }
}
