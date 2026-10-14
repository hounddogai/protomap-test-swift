import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a lenient network score must pass. Check returns its problems, or none.
    protocol LenientNetworkScoreRule {
        func check(_ item: LenientNetworkScore) -> [String]
    }

    final class LenientNetworkScoreRequiredLabelRule: LenientNetworkScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientNetworkScore) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientNetworkScoreLabelLengthRule: LenientNetworkScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientNetworkScore) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientNetworkScoreCodePrefixRule: LenientNetworkScoreRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LenientNetworkScore) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LenientNetworkScorePinnedGuardRule: LenientNetworkScoreRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: LenientNetworkScore) -> [String] {
            if item.pinned && (item.floorValue > limit) {
                return ["floor value \(item.floorValue) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient network score.
    final class LenientNetworkScoreValidator {
        var rules: [any LenientNetworkScoreRule]

        init(rules: [any LenientNetworkScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientNetworkScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientNetworkScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientNetworkScore]) -> [String: [String]] {
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

    static func defaultLenientNetworkScoreValidator() -> LenientNetworkScoreValidator {
        return LenientNetworkScoreValidator(
            rules: [
                LenientNetworkScoreRequiredLabelRule(message: "lenient network score needs a value"),
                LenientNetworkScoreLabelLengthRule(maxLength: 16),
                LenientNetworkScoreCodePrefixRule(prefix: "X"),
                LenientNetworkScorePinnedGuardRule(limit: 3.7),
            ]
        )
    }
}
