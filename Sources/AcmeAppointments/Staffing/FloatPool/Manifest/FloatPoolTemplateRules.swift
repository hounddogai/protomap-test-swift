import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a float pool template must pass. Check returns its problems, or none.
    protocol FloatPoolTemplateRule {
        func check(_ item: FloatPoolTemplate) -> [String]
    }

    final class FloatPoolTemplateRequiredCodeRule: FloatPoolTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FloatPoolTemplate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FloatPoolTemplateSegmentLengthRule: FloatPoolTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FloatPoolTemplate) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FloatPoolTemplateRequiredLabelRule: FloatPoolTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FloatPoolTemplate) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FloatPoolTemplateNameLengthRule: FloatPoolTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FloatPoolTemplate) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FloatPoolTemplateAllowedLabelRule: FloatPoolTemplateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FloatPoolTemplate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is missing"]
            }
            return []
        }
    }

    /// Runs every rule of a float pool template.
    final class FloatPoolTemplateValidator {
        var rules: [any FloatPoolTemplateRule]

        init(rules: [any FloatPoolTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: FloatPoolTemplate) -> [String] {
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

        func requireValid(_ item: FloatPoolTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FloatPoolTemplate]) -> [String: [String]] {
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

    static func defaultFloatPoolTemplateValidator() -> FloatPoolTemplateValidator {
        return FloatPoolTemplateValidator(
            rules: [
                FloatPoolTemplateRequiredCodeRule(message: "float pool template needs an entry"),
                FloatPoolTemplateSegmentLengthRule(maxLength: 16),
                FloatPoolTemplateRequiredLabelRule(message: "float pool template needs a value"),
                FloatPoolTemplateNameLengthRule(maxLength: 1000),
                FloatPoolTemplateAllowedLabelRule(allowed: []),
            ]
        )
    }
}
