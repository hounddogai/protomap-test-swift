import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a care protocol exception must pass. Check returns its problems, or none.
    protocol CareProtocolExceptionRule {
        func check(_ item: CareProtocolException) -> [String]
    }

    final class CareProtocolExceptionCodeLengthRule: CareProtocolExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolException) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolExceptionChecksumLengthRule: CareProtocolExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolException) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolExceptionRequiredNameRule: CareProtocolExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolException) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a care protocol exception.
    final class CareProtocolExceptionValidator {
        var rules: [any CareProtocolExceptionRule]

        init(rules: [any CareProtocolExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolException) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CareProtocolException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolException]) -> [String: [String]] {
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

    static func defaultCareProtocolExceptionValidator() -> CareProtocolExceptionValidator {
        return CareProtocolExceptionValidator(
            rules: [
                CareProtocolExceptionCodeLengthRule(maxLength: 86400),
                CareProtocolExceptionChecksumLengthRule(maxLength: 32),
                CareProtocolExceptionRequiredNameRule(message: "care protocol exception needs a value"),
            ]
        )
    }
}
