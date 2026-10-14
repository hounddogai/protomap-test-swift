import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a bed board bundle must pass. Check returns its problems, or none.
    protocol BedBoardBundleRule {
        func check(_ item: BedBoardBundle) -> [String]
    }

    final class BedBoardBundleAllowedFacilityRule: BedBoardBundleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BedBoardBundle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.facility)) {
                return ["facility \(item.facility) is below minimum"]
            }
            return []
        }
    }

    final class BedBoardBundleExternalRefLengthRule: BedBoardBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BedBoardBundle) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BedBoardBundleRequiredExternalRefRule: BedBoardBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BedBoardBundle) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BedBoardBundleCodePrefixRule: BedBoardBundleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BedBoardBundle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a bed board bundle.
    final class BedBoardBundleValidator {
        var rules: [any BedBoardBundleRule]

        init(rules: [any BedBoardBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: BedBoardBundle) -> [String] {
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

        func requireValid(_ item: BedBoardBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BedBoardBundle]) -> [String: [String]] {
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

    static func defaultBedBoardBundleValidator() -> BedBoardBundleValidator {
        return BedBoardBundleValidator(
            rules: [
                BedBoardBundleAllowedFacilityRule(allowed: ["tiered", "fallback"]),
                BedBoardBundleExternalRefLengthRule(maxLength: 1000),
                BedBoardBundleRequiredExternalRefRule(message: "bed board bundle needs a value"),
                BedBoardBundleCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
