import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a pending overtime agreement must pass. Check returns its problems, or none.
    protocol PendingOvertimeAgreementRule {
        func check(_ item: PendingOvertimeAgreement) -> [String]
    }

    final class PendingOvertimeAgreementTitleLengthRule: PendingOvertimeAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingOvertimeAgreement) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingOvertimeAgreementMinimumRangeRule: PendingOvertimeAgreementRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingOvertimeAgreement) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingOvertimeAgreementCodePrefixRule: PendingOvertimeAgreementRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingOvertimeAgreement) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PendingOvertimeAgreementRetriesRangeRule: PendingOvertimeAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingOvertimeAgreement) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingOvertimeAgreementEndsAtRangeRule: PendingOvertimeAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingOvertimeAgreement) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending overtime agreement.
    final class PendingOvertimeAgreementValidator {
        var rules: [any PendingOvertimeAgreementRule]

        init(rules: [any PendingOvertimeAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingOvertimeAgreement) -> [String] {
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

        func requireValid(_ item: PendingOvertimeAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingOvertimeAgreement]) -> [String: [String]] {
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

    static func defaultPendingOvertimeAgreementValidator() -> PendingOvertimeAgreementValidator {
        return PendingOvertimeAgreementValidator(
            rules: [
                PendingOvertimeAgreementTitleLengthRule(maxLength: 86400),
                PendingOvertimeAgreementMinimumRangeRule(min: 4.2, max: 4954.1),
                PendingOvertimeAgreementCodePrefixRule(prefix: "OPS"),
                PendingOvertimeAgreementRetriesRangeRule(min: 32, max: 32),
                PendingOvertimeAgreementEndsAtRangeRule(min: 1000, max: 3600),
            ]
        )
    }
}
