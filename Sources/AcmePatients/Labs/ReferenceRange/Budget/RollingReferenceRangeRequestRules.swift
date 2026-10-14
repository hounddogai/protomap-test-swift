import AcmePlatform
import Foundation

extension Labs {
    /// A rule a rolling reference range request must pass. Check returns its problems, or none.
    protocol RollingReferenceRangeRequestRule {
        func check(_ item: RollingReferenceRangeRequest) -> [String]
    }

    final class RollingReferenceRangeRequestDescriptionLengthRule: RollingReferenceRangeRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingReferenceRangeRequest) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingReferenceRangeRequestRequiredLabelRule: RollingReferenceRangeRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingReferenceRangeRequest) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingReferenceRangeRequestRequiredCodeRule: RollingReferenceRangeRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingReferenceRangeRequest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingReferenceRangeRequestAcuityRangeRule: RollingReferenceRangeRequestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingReferenceRangeRequest) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingReferenceRangeRequestLabelLengthRule: RollingReferenceRangeRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingReferenceRangeRequest) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingReferenceRangeRequestCodePrefixRule: RollingReferenceRangeRequestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingReferenceRangeRequest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling reference range request.
    final class RollingReferenceRangeRequestValidator {
        var rules: [any RollingReferenceRangeRequestRule]

        init(rules: [any RollingReferenceRangeRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingReferenceRangeRequest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingReferenceRangeRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingReferenceRangeRequest]) -> [String: [String]] {
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

    static func defaultRollingReferenceRangeRequestValidator() -> RollingReferenceRangeRequestValidator {
        return RollingReferenceRangeRequestValidator(
            rules: [
                RollingReferenceRangeRequestDescriptionLengthRule(maxLength: 3600),
                RollingReferenceRangeRequestRequiredLabelRule(
                    message: "rolling reference range request needs this field"
                ),
                RollingReferenceRangeRequestRequiredCodeRule(
                    message: "rolling reference range request needs this field"
                ),
                RollingReferenceRangeRequestAcuityRangeRule(min: 1000, max: 86400),
                RollingReferenceRangeRequestLabelLengthRule(maxLength: 80),
                RollingReferenceRangeRequestCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
