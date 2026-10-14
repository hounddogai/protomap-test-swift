import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a care protocol window must pass. Check returns its problems, or none.
    protocol CareProtocolWindowRule {
        func check(_ item: CareProtocolWindow) -> [String]
    }

    final class CareProtocolWindowOwnerIDLengthRule: CareProtocolWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolWindow) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolWindowRequiredSourceRule: CareProtocolWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolWindow) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolWindowRequiredOwnerIDRule: CareProtocolWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolWindow) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a care protocol window.
    final class CareProtocolWindowValidator {
        var rules: [any CareProtocolWindowRule]

        init(rules: [any CareProtocolWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CareProtocolWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolWindow]) -> [String: [String]] {
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

    static func defaultCareProtocolWindowValidator() -> CareProtocolWindowValidator {
        return CareProtocolWindowValidator(
            rules: [
                CareProtocolWindowOwnerIDLengthRule(maxLength: 86400),
                CareProtocolWindowRequiredSourceRule(message: "care protocol window needs an entry"),
                CareProtocolWindowRequiredOwnerIDRule(message: "care protocol window needs a value"),
            ]
        )
    }
}
