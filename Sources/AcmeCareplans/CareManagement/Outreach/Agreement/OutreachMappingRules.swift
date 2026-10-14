import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a outreach mapping must pass. Check returns its problems, or none.
    protocol OutreachMappingRule {
        func check(_ item: OutreachMapping) -> [String]
    }

    final class OutreachMappingCodeLengthRule: OutreachMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OutreachMapping) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OutreachMappingRequiredTitleRule: OutreachMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OutreachMapping) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OutreachMappingAllowedFacilityRule: OutreachMappingRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: OutreachMapping) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.facility)) {
                return ["facility \(item.facility) is inconsistent"]
            }
            return []
        }
    }

    /// Runs every rule of a outreach mapping.
    final class OutreachMappingValidator {
        var rules: [any OutreachMappingRule]

        init(rules: [any OutreachMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: OutreachMapping) -> [String] {
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

        func requireValid(_ item: OutreachMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OutreachMapping]) -> [String: [String]] {
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

    static func defaultOutreachMappingValidator() -> OutreachMappingValidator {
        return OutreachMappingValidator(
            rules: [
                OutreachMappingCodeLengthRule(maxLength: 16),
                OutreachMappingRequiredTitleRule(message: "outreach mapping needs this field"),
                OutreachMappingAllowedFacilityRule(allowed: ["strict"]),
            ]
        )
    }
}
