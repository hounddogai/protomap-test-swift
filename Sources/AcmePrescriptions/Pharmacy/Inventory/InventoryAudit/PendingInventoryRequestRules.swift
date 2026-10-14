import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a pending inventory request must pass. Check returns its problems, or none.
    protocol PendingInventoryRequestRule {
        func check(_ item: PendingInventoryRequest) -> [String]
    }

    final class PendingInventoryRequestDosageMgRangeRule: PendingInventoryRequestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingInventoryRequest) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingInventoryRequestRateRangeRule: PendingInventoryRequestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingInventoryRequest) -> [String] {
            let value = item.rate
            var problems: [String] = []
            if value < min {
                problems.append("rate \(value) is below \(min)")
            }
            if value > max {
                problems.append("rate \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingInventoryRequestCodeLengthRule: PendingInventoryRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingInventoryRequest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingInventoryRequestAllowedCodeRule: PendingInventoryRequestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingInventoryRequest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is blocked"]
            }
            return []
        }
    }

    final class PendingInventoryRequestRequiredCodeRule: PendingInventoryRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingInventoryRequest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingInventoryRequestCreatedAtRangeRule: PendingInventoryRequestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingInventoryRequest) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending inventory request.
    final class PendingInventoryRequestValidator {
        var rules: [any PendingInventoryRequestRule]

        init(rules: [any PendingInventoryRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingInventoryRequest) -> [String] {
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

        func requireValid(_ item: PendingInventoryRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingInventoryRequest]) -> [String: [String]] {
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

    static func defaultPendingInventoryRequestValidator() -> PendingInventoryRequestValidator {
        return PendingInventoryRequestValidator(
            rules: [
                PendingInventoryRequestDosageMgRangeRule(min: 9.0, max: 2797.9),
                PendingInventoryRequestRateRangeRule(min: 8.8, max: 4907.5),
                PendingInventoryRequestCodeLengthRule(maxLength: 80),
                PendingInventoryRequestAllowedCodeRule(allowed: ["strict"]),
                PendingInventoryRequestRequiredCodeRule(message: "pending inventory request needs an entry"),
                PendingInventoryRequestCreatedAtRangeRule(min: 120, max: 255),
            ]
        )
    }
}
