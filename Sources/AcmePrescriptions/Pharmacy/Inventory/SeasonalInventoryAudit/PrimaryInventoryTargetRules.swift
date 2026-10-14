import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a primary inventory target must pass. Check returns its problems, or none.
    protocol PrimaryInventoryTargetRule {
        func check(_ item: PrimaryInventoryTarget) -> [String]
    }

    final class PrimaryInventoryTargetCodePrefixRule: PrimaryInventoryTargetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimaryInventoryTarget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PrimaryInventoryTargetRequiredExternalRefRule: PrimaryInventoryTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryInventoryTarget) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryInventoryTargetNameLengthRule: PrimaryInventoryTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryInventoryTarget) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryInventoryTargetRequiredNameRule: PrimaryInventoryTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryInventoryTarget) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryInventoryTargetRequiredChannelRule: PrimaryInventoryTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryInventoryTarget) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryInventoryTargetCodeLengthRule: PrimaryInventoryTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryInventoryTarget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary inventory target.
    final class PrimaryInventoryTargetValidator {
        var rules: [any PrimaryInventoryTargetRule]

        init(rules: [any PrimaryInventoryTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryInventoryTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryInventoryTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryInventoryTarget]) -> [String: [String]] {
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

    static func defaultPrimaryInventoryTargetValidator() -> PrimaryInventoryTargetValidator {
        return PrimaryInventoryTargetValidator(
            rules: [
                PrimaryInventoryTargetCodePrefixRule(prefix: "REF"),
                PrimaryInventoryTargetRequiredExternalRefRule(message: "primary inventory target needs this field"),
                PrimaryInventoryTargetNameLengthRule(maxLength: 3600),
                PrimaryInventoryTargetRequiredNameRule(message: "primary inventory target needs an entry"),
                PrimaryInventoryTargetRequiredChannelRule(message: "primary inventory target needs an entry"),
                PrimaryInventoryTargetCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
