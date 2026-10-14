import AcmePlatform
import Foundation

extension Labs {
    /// A rule a primary result window must pass. Check returns its problems, or none.
    protocol PrimaryResultWindowRule {
        func check(_ item: PrimaryResultWindow) -> [String]
    }

    final class PrimaryResultWindowDiagnosisCodeLengthRule: PrimaryResultWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryResultWindow) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryResultWindowCodeLengthRule: PrimaryResultWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryResultWindow) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryResultWindowSourceLengthRule: PrimaryResultWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryResultWindow) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary result window.
    final class PrimaryResultWindowValidator {
        var rules: [any PrimaryResultWindowRule]

        init(rules: [any PrimaryResultWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryResultWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryResultWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryResultWindow]) -> [String: [String]] {
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

    static func defaultPrimaryResultWindowValidator() -> PrimaryResultWindowValidator {
        return PrimaryResultWindowValidator(
            rules: [
                PrimaryResultWindowDiagnosisCodeLengthRule(maxLength: 1000),
                PrimaryResultWindowCodeLengthRule(maxLength: 16),
                PrimaryResultWindowSourceLengthRule(maxLength: 1000),
            ]
        )
    }
}
