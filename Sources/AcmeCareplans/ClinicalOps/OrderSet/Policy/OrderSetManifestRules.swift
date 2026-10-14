import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a order set manifest must pass. Check returns its problems, or none.
    protocol OrderSetManifestRule {
        func check(_ item: OrderSetManifest) -> [String]
    }

    final class OrderSetManifestPriorityRangeRule: OrderSetManifestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OrderSetManifest) -> [String] {
            let value = item.priority
            var problems: [String] = []
            if value < min {
                problems.append("priority \(value) is below \(min)")
            }
            if value > max {
                problems.append("priority \(value) is above \(max)")
            }
            return problems
        }
    }

    final class OrderSetManifestClinicianIDLengthRule: OrderSetManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OrderSetManifest) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OrderSetManifestCodePrefixRule: OrderSetManifestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: OrderSetManifest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class OrderSetManifestTitleLengthRule: OrderSetManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OrderSetManifest) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a order set manifest.
    final class OrderSetManifestValidator {
        var rules: [any OrderSetManifestRule]

        init(rules: [any OrderSetManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: OrderSetManifest) -> [String] {
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

        func requireValid(_ item: OrderSetManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OrderSetManifest]) -> [String: [String]] {
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

    static func defaultOrderSetManifestValidator() -> OrderSetManifestValidator {
        return OrderSetManifestValidator(
            rules: [
                OrderSetManifestPriorityRangeRule(min: 80, max: 86400),
                OrderSetManifestClinicianIDLengthRule(maxLength: 255),
                OrderSetManifestCodePrefixRule(prefix: "OPS"),
                OrderSetManifestTitleLengthRule(maxLength: 86400),
            ]
        )
    }
}
