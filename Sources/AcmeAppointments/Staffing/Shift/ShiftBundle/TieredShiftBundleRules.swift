import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a tiered shift bundle must pass. Check returns its problems, or none.
    protocol TieredShiftBundleRule {
        func check(_ item: TieredShiftBundle) -> [String]
    }

    final class TieredShiftBundleApprovedGuardRule: TieredShiftBundleRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: TieredShiftBundle) -> [String] {
            if item.approved && (item.durationMinutes > limit) {
                return ["duration minutes \(item.durationMinutes) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class TieredShiftBundleRequiredExternalRefRule: TieredShiftBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredShiftBundle) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredShiftBundleTitleLengthRule: TieredShiftBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredShiftBundle) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredShiftBundleAllowedCodeRule: TieredShiftBundleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredShiftBundle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is duplicated"]
            }
            return []
        }
    }

    final class TieredShiftBundleRequiredCodeRule: TieredShiftBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredShiftBundle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a tiered shift bundle.
    final class TieredShiftBundleValidator {
        var rules: [any TieredShiftBundleRule]

        init(rules: [any TieredShiftBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredShiftBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredShiftBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredShiftBundle]) -> [String: [String]] {
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

    static func defaultTieredShiftBundleValidator() -> TieredShiftBundleValidator {
        return TieredShiftBundleValidator(
            rules: [
                TieredShiftBundleApprovedGuardRule(limit: 64),
                TieredShiftBundleRequiredExternalRefRule(message: "tiered shift bundle needs this field"),
                TieredShiftBundleTitleLengthRule(maxLength: 16),
                TieredShiftBundleAllowedCodeRule(allowed: []),
                TieredShiftBundleRequiredCodeRule(message: "tiered shift bundle needs a value"),
            ]
        )
    }
}
