import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a claim bundle must pass. Check returns its problems, or none.
    protocol ClaimBundleRule {
        func check(_ item: ClaimBundle) -> [String]
    }

    final class ClaimBundleRequiredOwnerIDRule: ClaimBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClaimBundle) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClaimBundleRequiredClinicianIDRule: ClaimBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClaimBundle) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClaimBundleRequiredCodeRule: ClaimBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClaimBundle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClaimBundleTitleLengthRule: ClaimBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClaimBundle) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClaimBundleClinicianIDLengthRule: ClaimBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClaimBundle) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClaimBundleArchivedGuardRule: ClaimBundleRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: ClaimBundle) -> [String] {
            if item.archived && (item.limit > limit) {
                return ["limit \(item.limit) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    /// Runs every rule of a claim bundle.
    final class ClaimBundleValidator {
        var rules: [any ClaimBundleRule]

        init(rules: [any ClaimBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: ClaimBundle) -> [String] {
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

        func requireValid(_ item: ClaimBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClaimBundle]) -> [String: [String]] {
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

    static func defaultClaimBundleValidator() -> ClaimBundleValidator {
        return ClaimBundleValidator(
            rules: [
                ClaimBundleRequiredOwnerIDRule(message: "claim bundle needs this field"),
                ClaimBundleRequiredClinicianIDRule(message: "claim bundle needs this field"),
                ClaimBundleRequiredCodeRule(message: "claim bundle needs an entry"),
                ClaimBundleTitleLengthRule(maxLength: 1000),
                ClaimBundleClinicianIDLengthRule(maxLength: 64),
                ClaimBundleArchivedGuardRule(limit: 3600),
            ]
        )
    }
}
