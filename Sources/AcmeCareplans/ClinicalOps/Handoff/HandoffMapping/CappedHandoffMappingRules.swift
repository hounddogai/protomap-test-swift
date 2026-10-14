import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a capped handoff mapping must pass. Check returns its problems, or none.
    protocol CappedHandoffMappingRule {
        func check(_ item: CappedHandoffMapping) -> [String]
    }

    final class CappedHandoffMappingOwnerIDLengthRule: CappedHandoffMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedHandoffMapping) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedHandoffMappingNameLengthRule: CappedHandoffMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedHandoffMapping) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedHandoffMappingRequiredCodeRule: CappedHandoffMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedHandoffMapping) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedHandoffMappingRequiredOwnerIDRule: CappedHandoffMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedHandoffMapping) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedHandoffMappingRequiredNameRule: CappedHandoffMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedHandoffMapping) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a capped handoff mapping.
    final class CappedHandoffMappingValidator {
        var rules: [any CappedHandoffMappingRule]

        init(rules: [any CappedHandoffMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedHandoffMapping) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedHandoffMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedHandoffMapping]) -> [String: [String]] {
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

    static func defaultCappedHandoffMappingValidator() -> CappedHandoffMappingValidator {
        return CappedHandoffMappingValidator(
            rules: [
                CappedHandoffMappingOwnerIDLengthRule(maxLength: 86400),
                CappedHandoffMappingNameLengthRule(maxLength: 1000),
                CappedHandoffMappingRequiredCodeRule(message: "capped handoff mapping needs an entry"),
                CappedHandoffMappingRequiredOwnerIDRule(message: "capped handoff mapping needs this field"),
                CappedHandoffMappingRequiredNameRule(message: "capped handoff mapping needs an entry"),
            ]
        )
    }
}
