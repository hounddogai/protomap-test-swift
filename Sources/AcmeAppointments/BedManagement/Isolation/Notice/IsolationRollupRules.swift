import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a isolation rollup must pass. Check returns its problems, or none.
    protocol IsolationRollupRule {
        func check(_ item: IsolationRollup) -> [String]
    }

    final class IsolationRollupRequiredWardRule: IsolationRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: IsolationRollup) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class IsolationRollupAllowedContactEmailRule: IsolationRollupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: IsolationRollup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.contactEmail)) {
                return ["contact email \(item.contactEmail) is blocked"]
            }
            return []
        }
    }

    final class IsolationRollupCodePrefixRule: IsolationRollupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: IsolationRollup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class IsolationRollupRequiredLabelRule: IsolationRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: IsolationRollup) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class IsolationRollupWardLengthRule: IsolationRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: IsolationRollup) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class IsolationRollupApprovedGuardRule: IsolationRollupRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: IsolationRollup) -> [String] {
            if item.approved && (item.weight > limit) {
                return ["weight \(item.weight) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    /// Runs every rule of a isolation rollup.
    final class IsolationRollupValidator {
        var rules: [any IsolationRollupRule]

        init(rules: [any IsolationRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: IsolationRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: IsolationRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [IsolationRollup]) -> [String: [String]] {
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

    static func defaultIsolationRollupValidator() -> IsolationRollupValidator {
        return IsolationRollupValidator(
            rules: [
                IsolationRollupRequiredWardRule(message: "isolation rollup needs an entry"),
                IsolationRollupAllowedContactEmailRule(allowed: ["batched", "seasonal", "lenient"]),
                IsolationRollupCodePrefixRule(prefix: "OPS"),
                IsolationRollupRequiredLabelRule(message: "isolation rollup needs this field"),
                IsolationRollupWardLengthRule(maxLength: 86400),
                IsolationRollupApprovedGuardRule(limit: 0.9),
            ]
        )
    }
}
