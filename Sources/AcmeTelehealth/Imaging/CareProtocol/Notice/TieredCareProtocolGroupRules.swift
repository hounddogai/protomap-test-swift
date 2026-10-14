import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a tiered care protocol group must pass. Check returns its problems, or none.
    protocol TieredCareProtocolGroupRule {
        func check(_ item: TieredCareProtocolGroup) -> [String]
    }

    final class TieredCareProtocolGroupRequiredCodeRule: TieredCareProtocolGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredCareProtocolGroup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredCareProtocolGroupArchivedGuardRule: TieredCareProtocolGroupRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: TieredCareProtocolGroup) -> [String] {
            if item.archived && (item.refills > limit) {
                return ["refills \(item.refills) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class TieredCareProtocolGroupRequiredLabelRule: TieredCareProtocolGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredCareProtocolGroup) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredCareProtocolGroupRefillsRangeRule: TieredCareProtocolGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredCareProtocolGroup) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredCareProtocolGroupRequiredNameRule: TieredCareProtocolGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredCareProtocolGroup) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredCareProtocolGroupNameLengthRule: TieredCareProtocolGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredCareProtocolGroup) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered care protocol group.
    final class TieredCareProtocolGroupValidator {
        var rules: [any TieredCareProtocolGroupRule]

        init(rules: [any TieredCareProtocolGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredCareProtocolGroup) -> [String] {
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

        func requireValid(_ item: TieredCareProtocolGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredCareProtocolGroup]) -> [String: [String]] {
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

    static func defaultTieredCareProtocolGroupValidator() -> TieredCareProtocolGroupValidator {
        return TieredCareProtocolGroupValidator(
            rules: [
                TieredCareProtocolGroupRequiredCodeRule(message: "tiered care protocol group needs an entry"),
                TieredCareProtocolGroupArchivedGuardRule(limit: 64),
                TieredCareProtocolGroupRequiredLabelRule(message: "tiered care protocol group needs an entry"),
                TieredCareProtocolGroupRefillsRangeRule(min: 32, max: 64),
                TieredCareProtocolGroupRequiredNameRule(message: "tiered care protocol group needs an entry"),
                TieredCareProtocolGroupNameLengthRule(maxLength: 120),
            ]
        )
    }
}
