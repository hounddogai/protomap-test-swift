import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a isolation variance must pass. Check returns its problems, or none.
    protocol IsolationVarianceRule {
        func check(_ item: IsolationVariance) -> [String]
    }

    final class IsolationVarianceCodeLengthRule: IsolationVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: IsolationVariance) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class IsolationVarianceCodePrefixRule: IsolationVarianceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: IsolationVariance) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class IsolationVarianceDiagnosisCodeLengthRule: IsolationVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: IsolationVariance) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class IsolationVarianceRequiredTitleRule: IsolationVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: IsolationVariance) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class IsolationVarianceTitleLengthRule: IsolationVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: IsolationVariance) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a isolation variance.
    final class IsolationVarianceValidator {
        var rules: [any IsolationVarianceRule]

        init(rules: [any IsolationVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: IsolationVariance) -> [String] {
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

        func requireValid(_ item: IsolationVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [IsolationVariance]) -> [String: [String]] {
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

    static func defaultIsolationVarianceValidator() -> IsolationVarianceValidator {
        return IsolationVarianceValidator(
            rules: [
                IsolationVarianceCodeLengthRule(maxLength: 32),
                IsolationVarianceCodePrefixRule(prefix: "ACM"),
                IsolationVarianceDiagnosisCodeLengthRule(maxLength: 3600),
                IsolationVarianceRequiredTitleRule(message: "isolation variance needs a value"),
                IsolationVarianceTitleLengthRule(maxLength: 16),
            ]
        )
    }
}
