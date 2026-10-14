import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the outreach notice calculation.
    protocol OutreachNoticeAdjuster {
        func describe() -> String
        func adjust(_ item: OutreachNotice, value: Double) -> Double
    }

    final class MinimumOutreachNoticeAdjuster: OutreachNoticeAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: OutreachNotice, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class SourceOutreachNoticeAdjuster: OutreachNoticeAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: OutreachNotice, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class OutreachNoticeRetriesOffsetAdjuster: OutreachNoticeAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus retries times \(weight)"
        }

        func adjust(_ item: OutreachNotice, value: Double) -> Double {
            return value + Double(item.retries) * weight
        }
    }

    /// Runs the outreach notice steps in order and keeps a trace of each.
    final class OutreachNoticeEngine {
        var steps: [any OutreachNoticeAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OutreachNoticeAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: OutreachNotice) -> Double {
            var current = item.projectedTotal()
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

        func evaluateAll(_ items: [OutreachNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultOutreachNoticeEngine() -> OutreachNoticeEngine {
        return OutreachNoticeEngine(
            steps: [
                MinimumOutreachNoticeAdjuster(minimum: 22.3),
                SourceOutreachNoticeAdjuster(factors: ["east": 0.83]),
                OutreachNoticeRetriesOffsetAdjuster(weight: 1.24),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 87922.1
        )
    }
}
