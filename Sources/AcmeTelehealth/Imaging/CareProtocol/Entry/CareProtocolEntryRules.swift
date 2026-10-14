import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a care protocol entry must pass. Check returns its problems, or none.
    protocol CareProtocolEntryRule {
        func check(_ item: CareProtocolEntry) -> [String]
    }

    final class CareProtocolEntryRequiredCodeRule: CareProtocolEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolEntry) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolEntryNameLengthRule: CareProtocolEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolEntry) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolEntryCodeLengthRule: CareProtocolEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolEntry) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolEntryRequiredWardRule: CareProtocolEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolEntry) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a care protocol entry.
    final class CareProtocolEntryValidator {
        var rules: [any CareProtocolEntryRule]

        init(rules: [any CareProtocolEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CareProtocolEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolEntry]) -> [String: [String]] {
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

    static func defaultCareProtocolEntryValidator() -> CareProtocolEntryValidator {
        return CareProtocolEntryValidator(
            rules: [
                CareProtocolEntryRequiredCodeRule(message: "care protocol entry needs an entry"),
                CareProtocolEntryNameLengthRule(maxLength: 120),
                CareProtocolEntryCodeLengthRule(maxLength: 32),
                CareProtocolEntryRequiredWardRule(message: "care protocol entry needs an entry"),
            ]
        )
    }
}
