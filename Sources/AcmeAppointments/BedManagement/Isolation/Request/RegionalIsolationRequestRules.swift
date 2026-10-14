import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a regional isolation request must pass. Check returns its problems, or none.
    protocol RegionalIsolationRequestRule {
        func check(_ item: RegionalIsolationRequest) -> [String]
    }

    final class RegionalIsolationRequestRequiredUnitRule: RegionalIsolationRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalIsolationRequest) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalIsolationRequestAllowedLabelRule: RegionalIsolationRequestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RegionalIsolationRequest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is inconsistent"]
            }
            return []
        }
    }

    final class RegionalIsolationRequestRequiredTitleRule: RegionalIsolationRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalIsolationRequest) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalIsolationRequestUnitLengthRule: RegionalIsolationRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalIsolationRequest) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalIsolationRequestTagsLimitRule: RegionalIsolationRequestRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: RegionalIsolationRequest) -> [String] {
            var problems: [String] = []
            if item.tags.count > maxCount {
                problems.append("has \(item.tags.count) tags, at most \(maxCount) allowed")
            }
            for tag in item.tags {
                if banned.contains(tag) {
                    problems.append("tag \(tag) is not allowed")
                }
            }
            return problems
        }
    }

    final class RegionalIsolationRequestCodeLengthRule: RegionalIsolationRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalIsolationRequest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional isolation request.
    final class RegionalIsolationRequestValidator {
        var rules: [any RegionalIsolationRequestRule]

        init(rules: [any RegionalIsolationRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalIsolationRequest) -> [String] {
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

        func requireValid(_ item: RegionalIsolationRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalIsolationRequest]) -> [String: [String]] {
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

    static func defaultRegionalIsolationRequestValidator() -> RegionalIsolationRequestValidator {
        return RegionalIsolationRequestValidator(
            rules: [
                RegionalIsolationRequestRequiredUnitRule(message: "regional isolation request needs a value"),
                RegionalIsolationRequestAllowedLabelRule(allowed: ["weighted", "adaptive", "tiered"]),
                RegionalIsolationRequestRequiredTitleRule(message: "regional isolation request needs this field"),
                RegionalIsolationRequestUnitLengthRule(maxLength: 86400),
                RegionalIsolationRequestTagsLimitRule(maxCount: 1000, banned: []),
                RegionalIsolationRequestCodeLengthRule(maxLength: 255),
            ]
        )
    }
}
