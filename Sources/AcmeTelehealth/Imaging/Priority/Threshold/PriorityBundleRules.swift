import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a priority bundle must pass. Check returns its problems, or none.
    protocol PriorityBundleRule {
        func check(_ item: PriorityBundle) -> [String]
    }

    final class PriorityBundleTitleLengthRule: PriorityBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PriorityBundle) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PriorityBundleAllowedSourceRule: PriorityBundleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PriorityBundle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.source)) {
                return ["source \(item.source) is expired"]
            }
            return []
        }
    }

    final class PriorityBundleRequiredSourceRule: PriorityBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PriorityBundle) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PriorityBundleCodePrefixRule: PriorityBundleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PriorityBundle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PriorityBundleCodeLengthRule: PriorityBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PriorityBundle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a priority bundle.
    final class PriorityBundleValidator {
        var rules: [any PriorityBundleRule]

        init(rules: [any PriorityBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: PriorityBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PriorityBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PriorityBundle]) -> [String: [String]] {
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

    static func defaultPriorityBundleValidator() -> PriorityBundleValidator {
        return PriorityBundleValidator(
            rules: [
                PriorityBundleTitleLengthRule(maxLength: 64),
                PriorityBundleAllowedSourceRule(allowed: ["scheduled"]),
                PriorityBundleRequiredSourceRule(message: "priority bundle needs this field"),
                PriorityBundleCodePrefixRule(prefix: "X"),
                PriorityBundleCodeLengthRule(maxLength: 120),
            ]
        )
    }
}
