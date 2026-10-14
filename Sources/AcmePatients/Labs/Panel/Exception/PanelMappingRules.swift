import AcmePlatform
import Foundation

extension Labs {
    /// A rule a panel mapping must pass. Check returns its problems, or none.
    protocol PanelMappingRule {
        func check(_ item: PanelMapping) -> [String]
    }

    final class PanelMappingNameLengthRule: PanelMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PanelMapping) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PanelMappingRequiredNameRule: PanelMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelMapping) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PanelMappingOwnerIDLengthRule: PanelMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PanelMapping) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a panel mapping.
    final class PanelMappingValidator {
        var rules: [any PanelMappingRule]

        init(rules: [any PanelMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: PanelMapping) -> [String] {
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

        func requireValid(_ item: PanelMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PanelMapping]) -> [String: [String]] {
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

    static func defaultPanelMappingValidator() -> PanelMappingValidator {
        return PanelMappingValidator(
            rules: [
                PanelMappingNameLengthRule(maxLength: 1000),
                PanelMappingRequiredNameRule(message: "panel mapping needs an entry"),
                PanelMappingOwnerIDLengthRule(maxLength: 86400),
            ]
        )
    }
}
