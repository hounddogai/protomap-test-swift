import AcmePlatform
import Foundation

extension Labs {
    /// A rule a strict specimen adjustment must pass. Check returns its problems, or none.
    protocol StrictSpecimenAdjustmentRule {
        func check(_ item: StrictSpecimenAdjustment) -> [String]
    }

    final class StrictSpecimenAdjustmentAllowedContactEmailRule: StrictSpecimenAdjustmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StrictSpecimenAdjustment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.contactEmail)) {
                return ["contact email \(item.contactEmail) is unknown"]
            }
            return []
        }
    }

    final class StrictSpecimenAdjustmentRequiredCodeRule: StrictSpecimenAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictSpecimenAdjustment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictSpecimenAdjustmentCodePrefixRule: StrictSpecimenAdjustmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StrictSpecimenAdjustment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StrictSpecimenAdjustmentCodeLengthRule: StrictSpecimenAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictSpecimenAdjustment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictSpecimenAdjustmentNameLengthRule: StrictSpecimenAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictSpecimenAdjustment) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict specimen adjustment.
    final class StrictSpecimenAdjustmentValidator {
        var rules: [any StrictSpecimenAdjustmentRule]

        init(rules: [any StrictSpecimenAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictSpecimenAdjustment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictSpecimenAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictSpecimenAdjustment]) -> [String: [String]] {
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

    static func defaultStrictSpecimenAdjustmentValidator() -> StrictSpecimenAdjustmentValidator {
        return StrictSpecimenAdjustmentValidator(
            rules: [
                StrictSpecimenAdjustmentAllowedContactEmailRule(allowed: ["default", "rolling", "seasonal"]),
                StrictSpecimenAdjustmentRequiredCodeRule(message: "strict specimen adjustment needs a value"),
                StrictSpecimenAdjustmentCodePrefixRule(prefix: "ACM"),
                StrictSpecimenAdjustmentCodeLengthRule(maxLength: 16),
                StrictSpecimenAdjustmentNameLengthRule(maxLength: 120),
            ]
        )
    }
}
