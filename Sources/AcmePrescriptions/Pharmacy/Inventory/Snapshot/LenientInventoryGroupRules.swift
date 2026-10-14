import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a lenient inventory group must pass. Check returns its problems, or none.
    protocol LenientInventoryGroupRule {
        func check(_ item: LenientInventoryGroup) -> [String]
    }

    final class LenientInventoryGroupTitleLengthRule: LenientInventoryGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientInventoryGroup) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientInventoryGroupRequiredCodeRule: LenientInventoryGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientInventoryGroup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientInventoryGroupCodeLengthRule: LenientInventoryGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientInventoryGroup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientInventoryGroupPinnedGuardRule: LenientInventoryGroupRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: LenientInventoryGroup) -> [String] {
            if item.pinned && (item.refills > limit) {
                return ["refills \(item.refills) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class LenientInventoryGroupExternalRefLengthRule: LenientInventoryGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientInventoryGroup) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient inventory group.
    final class LenientInventoryGroupValidator {
        var rules: [any LenientInventoryGroupRule]

        init(rules: [any LenientInventoryGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientInventoryGroup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientInventoryGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientInventoryGroup]) -> [String: [String]] {
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

    static func defaultLenientInventoryGroupValidator() -> LenientInventoryGroupValidator {
        return LenientInventoryGroupValidator(
            rules: [
                LenientInventoryGroupTitleLengthRule(maxLength: 32),
                LenientInventoryGroupRequiredCodeRule(message: "lenient inventory group needs this field"),
                LenientInventoryGroupCodeLengthRule(maxLength: 3600),
                LenientInventoryGroupPinnedGuardRule(limit: 80),
                LenientInventoryGroupExternalRefLengthRule(maxLength: 255),
            ]
        )
    }
}
