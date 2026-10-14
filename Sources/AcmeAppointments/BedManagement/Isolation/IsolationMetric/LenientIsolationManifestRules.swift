import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a lenient isolation manifest must pass. Check returns its problems, or none.
    protocol LenientIsolationManifestRule {
        func check(_ item: LenientIsolationManifest) -> [String]
    }

    final class LenientIsolationManifestTitleLengthRule: LenientIsolationManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientIsolationManifest) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientIsolationManifestCodePrefixRule: LenientIsolationManifestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LenientIsolationManifest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LenientIsolationManifestRequiredPayerRule: LenientIsolationManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientIsolationManifest) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientIsolationManifestCodeLengthRule: LenientIsolationManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientIsolationManifest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient isolation manifest.
    final class LenientIsolationManifestValidator {
        var rules: [any LenientIsolationManifestRule]

        init(rules: [any LenientIsolationManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientIsolationManifest) -> [String] {
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

        func requireValid(_ item: LenientIsolationManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientIsolationManifest]) -> [String: [String]] {
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

    static func defaultLenientIsolationManifestValidator() -> LenientIsolationManifestValidator {
        return LenientIsolationManifestValidator(
            rules: [
                LenientIsolationManifestTitleLengthRule(maxLength: 1000),
                LenientIsolationManifestCodePrefixRule(prefix: "OPS"),
                LenientIsolationManifestRequiredPayerRule(message: "lenient isolation manifest needs an entry"),
                LenientIsolationManifestCodeLengthRule(maxLength: 255),
            ]
        )
    }
}
