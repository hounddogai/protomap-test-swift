import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a lenient care gap entry must pass. Check returns its problems, or none.
    protocol LenientCareGapEntryRule {
        func check(_ item: LenientCareGapEntry) -> [String]
    }

    final class LenientCareGapEntryRequiredDescriptionRule: LenientCareGapEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientCareGapEntry) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientCareGapEntryArchivedGuardRule: LenientCareGapEntryRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: LenientCareGapEntry) -> [String] {
            if item.archived && (item.quantity > limit) {
                return ["quantity \(item.quantity) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class LenientCareGapEntryRequiredCodeRule: LenientCareGapEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientCareGapEntry) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientCareGapEntryChecksumLengthRule: LenientCareGapEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientCareGapEntry) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientCareGapEntryCodeLengthRule: LenientCareGapEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientCareGapEntry) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient care gap entry.
    final class LenientCareGapEntryValidator {
        var rules: [any LenientCareGapEntryRule]

        init(rules: [any LenientCareGapEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientCareGapEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientCareGapEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientCareGapEntry]) -> [String: [String]] {
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

    static func defaultLenientCareGapEntryValidator() -> LenientCareGapEntryValidator {
        return LenientCareGapEntryValidator(
            rules: [
                LenientCareGapEntryRequiredDescriptionRule(message: "lenient care gap entry needs this field"),
                LenientCareGapEntryArchivedGuardRule(limit: 255),
                LenientCareGapEntryRequiredCodeRule(message: "lenient care gap entry needs a value"),
                LenientCareGapEntryChecksumLengthRule(maxLength: 86400),
                LenientCareGapEntryCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
