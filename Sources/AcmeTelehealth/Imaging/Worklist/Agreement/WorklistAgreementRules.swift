import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a worklist agreement must pass. Check returns its problems, or none.
    protocol WorklistAgreementRule {
        func check(_ item: WorklistAgreement) -> [String]
    }

    final class WorklistAgreementVisibleGuardRule: WorklistAgreementRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: WorklistAgreement) -> [String] {
            if item.visible && (item.updatedAt > limit) {
                return ["updated at \(item.updatedAt) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class WorklistAgreementDiagnosisCodeLengthRule: WorklistAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WorklistAgreement) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WorklistAgreementCodePrefixRule: WorklistAgreementRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WorklistAgreement) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a worklist agreement.
    final class WorklistAgreementValidator {
        var rules: [any WorklistAgreementRule]

        init(rules: [any WorklistAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: WorklistAgreement) -> [String] {
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

        func requireValid(_ item: WorklistAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WorklistAgreement]) -> [String: [String]] {
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

    static func defaultWorklistAgreementValidator() -> WorklistAgreementValidator {
        return WorklistAgreementValidator(
            rules: [
                WorklistAgreementVisibleGuardRule(limit: 255),
                WorklistAgreementDiagnosisCodeLengthRule(maxLength: 64),
                WorklistAgreementCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
