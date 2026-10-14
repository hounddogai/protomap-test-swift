import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a default risk score batch must pass. Check returns its problems, or none.
    protocol DefaultRiskScoreBatchRule {
        func check(_ item: DefaultRiskScoreBatch) -> [String]
    }

    final class DefaultRiskScoreBatchNameLengthRule: DefaultRiskScoreBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultRiskScoreBatch) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultRiskScoreBatchCodeLengthRule: DefaultRiskScoreBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultRiskScoreBatch) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultRiskScoreBatchRequiredFacilityRule: DefaultRiskScoreBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultRiskScoreBatch) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultRiskScoreBatchApprovedGuardRule: DefaultRiskScoreBatchRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: DefaultRiskScoreBatch) -> [String] {
            if item.approved && (item.startsAt > limit) {
                return ["starts at \(item.startsAt) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class DefaultRiskScoreBatchFacilityLengthRule: DefaultRiskScoreBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultRiskScoreBatch) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a default risk score batch.
    final class DefaultRiskScoreBatchValidator {
        var rules: [any DefaultRiskScoreBatchRule]

        init(rules: [any DefaultRiskScoreBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultRiskScoreBatch) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultRiskScoreBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultRiskScoreBatch]) -> [String: [String]] {
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

    static func defaultDefaultRiskScoreBatchValidator() -> DefaultRiskScoreBatchValidator {
        return DefaultRiskScoreBatchValidator(
            rules: [
                DefaultRiskScoreBatchNameLengthRule(maxLength: 80),
                DefaultRiskScoreBatchCodeLengthRule(maxLength: 16),
                DefaultRiskScoreBatchRequiredFacilityRule(message: "default risk score batch needs this field"),
                DefaultRiskScoreBatchApprovedGuardRule(limit: 86400),
                DefaultRiskScoreBatchFacilityLengthRule(maxLength: 3600),
            ]
        )
    }
}
