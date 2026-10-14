import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a rolling dispense profile must pass. Check returns its problems, or none.
    protocol RollingDispenseProfileRule {
        func check(_ item: RollingDispenseProfile) -> [String]
    }

    final class RollingDispenseProfileRequiredSourceRule: RollingDispenseProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingDispenseProfile) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingDispenseProfileRequiredClinicianIDRule: RollingDispenseProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingDispenseProfile) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingDispenseProfileTitleLengthRule: RollingDispenseProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingDispenseProfile) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingDispenseProfileRequiredTitleRule: RollingDispenseProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingDispenseProfile) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rolling dispense profile.
    final class RollingDispenseProfileValidator {
        var rules: [any RollingDispenseProfileRule]

        init(rules: [any RollingDispenseProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingDispenseProfile) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingDispenseProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingDispenseProfile]) -> [String: [String]] {
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

    static func defaultRollingDispenseProfileValidator() -> RollingDispenseProfileValidator {
        return RollingDispenseProfileValidator(
            rules: [
                RollingDispenseProfileRequiredSourceRule(message: "rolling dispense profile needs a value"),
                RollingDispenseProfileRequiredClinicianIDRule(message: "rolling dispense profile needs this field"),
                RollingDispenseProfileTitleLengthRule(maxLength: 32),
                RollingDispenseProfileRequiredTitleRule(message: "rolling dispense profile needs an entry"),
            ]
        )
    }
}
