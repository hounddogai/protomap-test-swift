import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a regional care protocol digest must pass. Check returns its problems, or none.
    protocol RegionalCareProtocolDigestRule {
        func check(_ item: RegionalCareProtocolDigest) -> [String]
    }

    final class RegionalCareProtocolDigestRequiredNameRule: RegionalCareProtocolDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalCareProtocolDigest) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalCareProtocolDigestRequiredWardRule: RegionalCareProtocolDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalCareProtocolDigest) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalCareProtocolDigestDiagnosisCodeLengthRule: RegionalCareProtocolDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalCareProtocolDigest) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalCareProtocolDigestRequiredDiagnosisCodeRule: RegionalCareProtocolDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalCareProtocolDigest) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalCareProtocolDigestWardLengthRule: RegionalCareProtocolDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalCareProtocolDigest) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalCareProtocolDigestArchivedGuardRule: RegionalCareProtocolDigestRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: RegionalCareProtocolDigest) -> [String] {
            if item.archived && (item.updatedAt > limit) {
                return ["updated at \(item.updatedAt) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    /// Runs every rule of a regional care protocol digest.
    final class RegionalCareProtocolDigestValidator {
        var rules: [any RegionalCareProtocolDigestRule]

        init(rules: [any RegionalCareProtocolDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalCareProtocolDigest) -> [String] {
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

        func requireValid(_ item: RegionalCareProtocolDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalCareProtocolDigest]) -> [String: [String]] {
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

    static func defaultRegionalCareProtocolDigestValidator() -> RegionalCareProtocolDigestValidator {
        return RegionalCareProtocolDigestValidator(
            rules: [
                RegionalCareProtocolDigestRequiredNameRule(message: "regional care protocol digest needs this field"),
                RegionalCareProtocolDigestRequiredWardRule(message: "regional care protocol digest needs this field"),
                RegionalCareProtocolDigestDiagnosisCodeLengthRule(maxLength: 32),
                RegionalCareProtocolDigestRequiredDiagnosisCodeRule(
                    message: "regional care protocol digest needs an entry"
                ),
                RegionalCareProtocolDigestWardLengthRule(maxLength: 86400),
                RegionalCareProtocolDigestArchivedGuardRule(limit: 120),
            ]
        )
    }
}
