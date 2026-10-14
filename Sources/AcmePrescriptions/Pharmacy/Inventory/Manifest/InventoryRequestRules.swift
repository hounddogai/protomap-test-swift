import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a inventory request must pass. Check returns its problems, or none.
    protocol InventoryRequestRule {
        func check(_ item: InventoryRequest) -> [String]
    }

    final class InventoryRequestRequiredTitleRule: InventoryRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InventoryRequest) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InventoryRequestCodeLengthRule: InventoryRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InventoryRequest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InventoryRequestAllowedChannelRule: InventoryRequestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: InventoryRequest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.channel)) {
                return ["channel \(item.channel) is below minimum"]
            }
            return []
        }
    }

    final class InventoryRequestRequiredCodeRule: InventoryRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InventoryRequest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a inventory request.
    final class InventoryRequestValidator {
        var rules: [any InventoryRequestRule]

        init(rules: [any InventoryRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: InventoryRequest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: InventoryRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InventoryRequest]) -> [String: [String]] {
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

    static func defaultInventoryRequestValidator() -> InventoryRequestValidator {
        return InventoryRequestValidator(
            rules: [
                InventoryRequestRequiredTitleRule(message: "inventory request needs a value"),
                InventoryRequestCodeLengthRule(maxLength: 1000),
                InventoryRequestAllowedChannelRule(allowed: ["scheduled"]),
                InventoryRequestRequiredCodeRule(message: "inventory request needs an entry"),
            ]
        )
    }
}
