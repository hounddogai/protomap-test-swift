import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a study cycle must pass. Check returns its problems, or none.
    protocol StudyCycleRule {
        func check(_ item: StudyCycle) -> [String]
    }

    final class StudyCycleAllowedBedRule: StudyCycleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StudyCycle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.bed)) {
                return ["bed \(item.bed) is above maximum"]
            }
            return []
        }
    }

    final class StudyCycleRequiredBedRule: StudyCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StudyCycle) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StudyCycleRequiredFacilityRule: StudyCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StudyCycle) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StudyCycleCodePrefixRule: StudyCycleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StudyCycle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StudyCycleLabelLengthRule: StudyCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StudyCycle) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a study cycle.
    final class StudyCycleValidator {
        var rules: [any StudyCycleRule]

        init(rules: [any StudyCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: StudyCycle) -> [String] {
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

        func requireValid(_ item: StudyCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StudyCycle]) -> [String: [String]] {
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

    static func defaultStudyCycleValidator() -> StudyCycleValidator {
        return StudyCycleValidator(
            rules: [
                StudyCycleAllowedBedRule(allowed: ["primary"]),
                StudyCycleRequiredBedRule(message: "study cycle needs an entry"),
                StudyCycleRequiredFacilityRule(message: "study cycle needs an entry"),
                StudyCycleCodePrefixRule(prefix: "OPS"),
                StudyCycleLabelLengthRule(maxLength: 16),
            ]
        )
    }
}
