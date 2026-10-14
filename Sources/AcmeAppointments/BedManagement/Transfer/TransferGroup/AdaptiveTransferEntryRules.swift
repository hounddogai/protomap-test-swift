import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a adaptive transfer entry must pass. Check returns its problems, or none.
    protocol AdaptiveTransferEntryRule {
        func check(_ item: AdaptiveTransferEntry) -> [String]
    }

    final class AdaptiveTransferEntryTitleLengthRule: AdaptiveTransferEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveTransferEntry) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveTransferEntryExternalRefLengthRule: AdaptiveTransferEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveTransferEntry) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveTransferEntryAllowedSummaryRule: AdaptiveTransferEntryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveTransferEntry) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.summary)) {
                return ["summary \(item.summary) is not allowed"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive transfer entry.
    final class AdaptiveTransferEntryValidator {
        var rules: [any AdaptiveTransferEntryRule]

        init(rules: [any AdaptiveTransferEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveTransferEntry) -> [String] {
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

        func requireValid(_ item: AdaptiveTransferEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveTransferEntry]) -> [String: [String]] {
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

    static func defaultAdaptiveTransferEntryValidator() -> AdaptiveTransferEntryValidator {
        return AdaptiveTransferEntryValidator(
            rules: [
                AdaptiveTransferEntryTitleLengthRule(maxLength: 1000),
                AdaptiveTransferEntryExternalRefLengthRule(maxLength: 80),
                AdaptiveTransferEntryAllowedSummaryRule(allowed: ["manual"]),
            ]
        )
    }
}
