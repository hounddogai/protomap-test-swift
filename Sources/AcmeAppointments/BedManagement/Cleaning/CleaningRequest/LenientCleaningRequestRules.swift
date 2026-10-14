import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a lenient cleaning request must pass. Check returns its problems, or none.
    protocol LenientCleaningRequestRule {
        func check(_ item: LenientCleaningRequest) -> [String]
    }

    final class LenientCleaningRequestRequiredChecksumRule: LenientCleaningRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientCleaningRequest) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientCleaningRequestLocaleLengthRule: LenientCleaningRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientCleaningRequest) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientCleaningRequestCodePrefixRule: LenientCleaningRequestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LenientCleaningRequest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LenientCleaningRequestRequiredNameRule: LenientCleaningRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientCleaningRequest) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a lenient cleaning request.
    final class LenientCleaningRequestValidator {
        var rules: [any LenientCleaningRequestRule]

        init(rules: [any LenientCleaningRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientCleaningRequest) -> [String] {
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

        func requireValid(_ item: LenientCleaningRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientCleaningRequest]) -> [String: [String]] {
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

    static func defaultLenientCleaningRequestValidator() -> LenientCleaningRequestValidator {
        return LenientCleaningRequestValidator(
            rules: [
                LenientCleaningRequestRequiredChecksumRule(message: "lenient cleaning request needs a value"),
                LenientCleaningRequestLocaleLengthRule(maxLength: 1000),
                LenientCleaningRequestCodePrefixRule(prefix: "Q"),
                LenientCleaningRequestRequiredNameRule(message: "lenient cleaning request needs this field"),
            ]
        )
    }
}
