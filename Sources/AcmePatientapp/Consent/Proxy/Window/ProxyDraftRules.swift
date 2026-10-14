import AcmePlatform
import Foundation

extension Consent {
    /// A rule a proxy draft must pass. Check returns its problems, or none.
    protocol ProxyDraftRule {
        func check(_ item: ProxyDraft) -> [String]
    }

    final class ProxyDraftCodePrefixRule: ProxyDraftRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ProxyDraft) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ProxyDraftOwnerIDLengthRule: ProxyDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProxyDraft) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProxyDraftLimitRangeRule: ProxyDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProxyDraft) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ProxyDraftSummaryLengthRule: ProxyDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProxyDraft) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a proxy draft.
    final class ProxyDraftValidator {
        var rules: [any ProxyDraftRule]

        init(rules: [any ProxyDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: ProxyDraft) -> [String] {
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

        func requireValid(_ item: ProxyDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProxyDraft]) -> [String: [String]] {
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

    static func defaultProxyDraftValidator() -> ProxyDraftValidator {
        return ProxyDraftValidator(
            rules: [
                ProxyDraftCodePrefixRule(prefix: "OPS"),
                ProxyDraftOwnerIDLengthRule(maxLength: 16),
                ProxyDraftLimitRangeRule(min: 80, max: 1000),
                ProxyDraftSummaryLengthRule(maxLength: 86400),
            ]
        )
    }
}
