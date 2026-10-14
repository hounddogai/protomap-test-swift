import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a tiered authorization bundle must pass. Check returns its problems, or none.
    protocol TieredAuthorizationBundleRule {
        func check(_ item: TieredAuthorizationBundle) -> [String]
    }

    final class TieredAuthorizationBundleTitleLengthRule: TieredAuthorizationBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredAuthorizationBundle) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredAuthorizationBundleRequiredTimezoneRule: TieredAuthorizationBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredAuthorizationBundle) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredAuthorizationBundleRequiredTitleRule: TieredAuthorizationBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredAuthorizationBundle) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredAuthorizationBundleChecksumLengthRule: TieredAuthorizationBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredAuthorizationBundle) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredAuthorizationBundleRequiredChecksumRule: TieredAuthorizationBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredAuthorizationBundle) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredAuthorizationBundleTimezoneLengthRule: TieredAuthorizationBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredAuthorizationBundle) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered authorization bundle.
    final class TieredAuthorizationBundleValidator {
        var rules: [any TieredAuthorizationBundleRule]

        init(rules: [any TieredAuthorizationBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredAuthorizationBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredAuthorizationBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredAuthorizationBundle]) -> [String: [String]] {
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

    static func defaultTieredAuthorizationBundleValidator() -> TieredAuthorizationBundleValidator {
        return TieredAuthorizationBundleValidator(
            rules: [
                TieredAuthorizationBundleTitleLengthRule(maxLength: 64),
                TieredAuthorizationBundleRequiredTimezoneRule(message: "tiered authorization bundle needs this field"),
                TieredAuthorizationBundleRequiredTitleRule(message: "tiered authorization bundle needs a value"),
                TieredAuthorizationBundleChecksumLengthRule(maxLength: 3600),
                TieredAuthorizationBundleRequiredChecksumRule(message: "tiered authorization bundle needs a value"),
                TieredAuthorizationBundleTimezoneLengthRule(maxLength: 80),
            ]
        )
    }
}
