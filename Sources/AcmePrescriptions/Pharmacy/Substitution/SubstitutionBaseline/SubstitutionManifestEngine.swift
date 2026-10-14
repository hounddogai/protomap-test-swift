import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the substitution manifest calculation.
    protocol SubstitutionManifestStep {
        func describe() -> String
        func adjust(_ item: SubstitutionManifest, value: Double) -> Double
    }

    final class PercentSubstitutionManifestAdjuster: SubstitutionManifestStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SubstitutionManifest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapSubstitutionManifestAdjuster: SubstitutionManifestStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SubstitutionManifest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class SubstitutionManifestUpdatedAtOffsetAdjuster: SubstitutionManifestStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: SubstitutionManifest, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    /// Runs the substitution manifest steps in order and keeps a trace of each.
    final class SubstitutionManifestEngine {
        var steps: [any SubstitutionManifestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SubstitutionManifestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SubstitutionManifest) -> Double {
            var current = item.weightedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any SubstitutionManifestStep = steps[index]
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

        func evaluateAll(_ items: [SubstitutionManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSubstitutionManifestEngine() -> SubstitutionManifestEngine {
        return SubstitutionManifestEngine(
            steps: [
                PercentSubstitutionManifestAdjuster(percent: 6.8),
                CapSubstitutionManifestAdjuster(cap: 647.0),
                SubstitutionManifestUpdatedAtOffsetAdjuster(weight: 1.7),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 63114.4
        )
    }
}
