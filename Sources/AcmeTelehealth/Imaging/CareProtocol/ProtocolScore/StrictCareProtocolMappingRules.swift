import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a strict care protocol mapping must pass. Check returns its problems, or none.
    protocol StrictCareProtocolMappingRule {
        func check(_ item: StrictCareProtocolMapping) -> [String]
    }

    final class StrictCareProtocolMappingNameLengthRule: StrictCareProtocolMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictCareProtocolMapping) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictCareProtocolMappingRequiredCodeRule: StrictCareProtocolMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictCareProtocolMapping) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictCareProtocolMappingRequiredTitleRule: StrictCareProtocolMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictCareProtocolMapping) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictCareProtocolMappingWardLengthRule: StrictCareProtocolMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictCareProtocolMapping) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictCareProtocolMappingRequiredNameRule: StrictCareProtocolMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictCareProtocolMapping) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a strict care protocol mapping.
    final class StrictCareProtocolMappingValidator {
        var rules: [any StrictCareProtocolMappingRule]

        init(rules: [any StrictCareProtocolMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictCareProtocolMapping) -> [String] {
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

        func requireValid(_ item: StrictCareProtocolMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictCareProtocolMapping]) -> [String: [String]] {
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

    static func defaultStrictCareProtocolMappingValidator() -> StrictCareProtocolMappingValidator {
        return StrictCareProtocolMappingValidator(
            rules: [
                StrictCareProtocolMappingNameLengthRule(maxLength: 1000),
                StrictCareProtocolMappingRequiredCodeRule(message: "strict care protocol mapping needs this field"),
                StrictCareProtocolMappingRequiredTitleRule(message: "strict care protocol mapping needs a value"),
                StrictCareProtocolMappingWardLengthRule(maxLength: 3600),
                StrictCareProtocolMappingRequiredNameRule(message: "strict care protocol mapping needs this field"),
            ]
        )
    }
}
