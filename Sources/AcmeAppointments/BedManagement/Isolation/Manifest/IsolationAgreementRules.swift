import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a isolation agreement must pass. Check returns its problems, or none.
    protocol IsolationAgreementRule {
        func check(_ item: IsolationAgreement) -> [String]
    }

    final class IsolationAgreementWindowDaysRangeRule: IsolationAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: IsolationAgreement) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class IsolationAgreementCodeLengthRule: IsolationAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: IsolationAgreement) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class IsolationAgreementAllowedCodeRule: IsolationAgreementRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: IsolationAgreement) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is out of range"]
            }
            return []
        }
    }

    /// Runs every rule of a isolation agreement.
    final class IsolationAgreementValidator {
        var rules: [any IsolationAgreementRule]

        init(rules: [any IsolationAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: IsolationAgreement) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: IsolationAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [IsolationAgreement]) -> [String: [String]] {
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

    static func defaultIsolationAgreementValidator() -> IsolationAgreementValidator {
        return IsolationAgreementValidator(
            rules: [
                IsolationAgreementWindowDaysRangeRule(min: 16, max: 80),
                IsolationAgreementCodeLengthRule(maxLength: 3600),
                IsolationAgreementAllowedCodeRule(allowed: []),
            ]
        )
    }
}
