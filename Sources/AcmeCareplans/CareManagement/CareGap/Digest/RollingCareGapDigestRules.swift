import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a rolling care gap digest must pass. Check returns its problems, or none.
    protocol RollingCareGapDigestRule {
        func check(_ item: RollingCareGapDigest) -> [String]
    }

    final class RollingCareGapDigestCodePrefixRule: RollingCareGapDigestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingCareGapDigest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RollingCareGapDigestFacilityLengthRule: RollingCareGapDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingCareGapDigest) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingCareGapDigestApprovedGuardRule: RollingCareGapDigestRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: RollingCareGapDigest) -> [String] {
            if item.approved && (item.endsAt > limit) {
                return ["ends at \(item.endsAt) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class RollingCareGapDigestRequiredFacilityRule: RollingCareGapDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingCareGapDigest) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rolling care gap digest.
    final class RollingCareGapDigestValidator {
        var rules: [any RollingCareGapDigestRule]

        init(rules: [any RollingCareGapDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingCareGapDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingCareGapDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingCareGapDigest]) -> [String: [String]] {
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

    static func defaultRollingCareGapDigestValidator() -> RollingCareGapDigestValidator {
        return RollingCareGapDigestValidator(
            rules: [
                RollingCareGapDigestCodePrefixRule(prefix: "X"),
                RollingCareGapDigestFacilityLengthRule(maxLength: 3600),
                RollingCareGapDigestApprovedGuardRule(limit: 86400),
                RollingCareGapDigestRequiredFacilityRule(message: "rolling care gap digest needs a value"),
            ]
        )
    }
}
