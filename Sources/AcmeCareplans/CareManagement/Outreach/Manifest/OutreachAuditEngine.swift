import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the outreach audit calculation.
    protocol OutreachAuditAdjuster {
        func describe() -> String
        func adjust(_ item: OutreachAudit, value: Double) -> Double
    }

    final class PercentOutreachAuditAdjuster: OutreachAuditAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: OutreachAudit, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class OutreachAuditUpdatedAtOffsetAdjuster: OutreachAuditAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: OutreachAudit, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    final class ChannelOutreachAuditAdjuster: OutreachAuditAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: OutreachAudit, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the outreach audit steps in order and keeps a trace of each.
    final class OutreachAuditEngine {
        var steps: [any OutreachAuditAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OutreachAuditAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: OutreachAudit) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any OutreachAuditAdjuster = steps[index]
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

        func evaluateAll(_ items: [OutreachAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultOutreachAuditEngine() -> OutreachAuditEngine {
        return OutreachAuditEngine(
            steps: [
                PercentOutreachAuditAdjuster(percent: -18.9),
                OutreachAuditUpdatedAtOffsetAdjuster(weight: 1.51),
                ChannelOutreachAuditAdjuster(factors: ["retail": 1.24, "online": 1.25]),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 5659.8
        )
    }
}
