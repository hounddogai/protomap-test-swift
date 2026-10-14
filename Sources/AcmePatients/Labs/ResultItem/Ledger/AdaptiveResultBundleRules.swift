import AcmePlatform
import Foundation

extension Labs {
    /// A rule a adaptive result bundle must pass. Check returns its problems, or none.
    protocol AdaptiveResultBundleRule {
        func check(_ item: AdaptiveResultBundle) -> [String]
    }

    final class AdaptiveResultBundleRequiredNameRule: AdaptiveResultBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveResultBundle) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveResultBundleNameLengthRule: AdaptiveResultBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveResultBundle) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveResultBundleRequiredCodeRule: AdaptiveResultBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveResultBundle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive result bundle.
    final class AdaptiveResultBundleValidator {
        var rules: [any AdaptiveResultBundleRule]

        init(rules: [any AdaptiveResultBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveResultBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveResultBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveResultBundle]) -> [String: [String]] {
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

    static func defaultAdaptiveResultBundleValidator() -> AdaptiveResultBundleValidator {
        return AdaptiveResultBundleValidator(
            rules: [
                AdaptiveResultBundleRequiredNameRule(message: "adaptive result bundle needs a value"),
                AdaptiveResultBundleNameLengthRule(maxLength: 64),
                AdaptiveResultBundleRequiredCodeRule(message: "adaptive result bundle needs a value"),
            ]
        )
    }
}
