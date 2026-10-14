import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a strict overtime agreement must pass. Check returns its problems, or none.
    protocol StrictOvertimeAgreementRule {
        func check(_ item: StrictOvertimeAgreement) -> [String]
    }

    final class StrictOvertimeAgreementCodePrefixRule: StrictOvertimeAgreementRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StrictOvertimeAgreement) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StrictOvertimeAgreementRequiredAllergyRule: StrictOvertimeAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictOvertimeAgreement) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictOvertimeAgreementRequiredSummaryRule: StrictOvertimeAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictOvertimeAgreement) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictOvertimeAgreementRequiredTitleRule: StrictOvertimeAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictOvertimeAgreement) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictOvertimeAgreementPinnedGuardRule: StrictOvertimeAgreementRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: StrictOvertimeAgreement) -> [String] {
            if item.pinned && (item.threshold > limit) {
                return ["threshold \(item.threshold) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class StrictOvertimeAgreementRetriesRangeRule: StrictOvertimeAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictOvertimeAgreement) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict overtime agreement.
    final class StrictOvertimeAgreementValidator {
        var rules: [any StrictOvertimeAgreementRule]

        init(rules: [any StrictOvertimeAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictOvertimeAgreement) -> [String] {
            var problems: [String] = []
            for rule in rules {
                let found = rule.check(item)
                if found.count == 0 {
                    continue
                }
                for problem in found {
                    problems.append("\(item.code): \(problem)")
                }
            }
            return problems
        }

        func requireValid(_ item: StrictOvertimeAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictOvertimeAgreement]) -> [String: [String]] {
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

    static func defaultStrictOvertimeAgreementValidator() -> StrictOvertimeAgreementValidator {
        return StrictOvertimeAgreementValidator(
            rules: [
                StrictOvertimeAgreementCodePrefixRule(prefix: "REF"),
                StrictOvertimeAgreementRequiredAllergyRule(message: "strict overtime agreement needs an entry"),
                StrictOvertimeAgreementRequiredSummaryRule(message: "strict overtime agreement needs this field"),
                StrictOvertimeAgreementRequiredTitleRule(message: "strict overtime agreement needs an entry"),
                StrictOvertimeAgreementPinnedGuardRule(limit: 8.4),
                StrictOvertimeAgreementRetriesRangeRule(min: 16, max: 120),
            ]
        )
    }
}
