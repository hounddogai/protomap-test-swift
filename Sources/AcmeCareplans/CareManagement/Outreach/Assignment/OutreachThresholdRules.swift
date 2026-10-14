import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a outreach threshold must pass. Check returns its problems, or none.
    protocol OutreachThresholdRule {
        func check(_ item: OutreachThreshold) -> [String]
    }

    final class OutreachThresholdRequiredCodeRule: OutreachThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OutreachThreshold) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OutreachThresholdRequiredWardRule: OutreachThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OutreachThreshold) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OutreachThresholdWeightRangeRule: OutreachThresholdRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: OutreachThreshold) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class OutreachThresholdApprovedGuardRule: OutreachThresholdRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: OutreachThreshold) -> [String] {
            if item.approved && (item.limit > limit) {
                return ["limit \(item.limit) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class OutreachThresholdRequiredTitleRule: OutreachThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OutreachThreshold) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a outreach threshold.
    final class OutreachThresholdValidator {
        var rules: [any OutreachThresholdRule]

        init(rules: [any OutreachThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: OutreachThreshold) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: OutreachThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OutreachThreshold]) -> [String: [String]] {
            var report: [String: [String]] = [:]
            for item in items {
                let problems = self.validate(item)
                if problems.count > 0 {
                    report[item.code] = problems
                }
            }
            return report
        }
    }

    static func defaultOutreachThresholdValidator() -> OutreachThresholdValidator {
        return OutreachThresholdValidator(
            rules: [
                OutreachThresholdRequiredCodeRule(message: "outreach threshold needs an entry"),
                OutreachThresholdRequiredWardRule(message: "outreach threshold needs this field"),
                OutreachThresholdWeightRangeRule(min: 5.8, max: 4619.6),
                OutreachThresholdApprovedGuardRule(limit: 3600),
                OutreachThresholdRequiredTitleRule(message: "outreach threshold needs this field"),
            ]
        )
    }
}
