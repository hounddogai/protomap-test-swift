import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a batched formulary bundle must pass. Check returns its problems, or none.
    protocol BatchedFormularyBundleRule {
        func check(_ item: BatchedFormularyBundle) -> [String]
    }

    final class BatchedFormularyBundleRequiredNameRule: BatchedFormularyBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedFormularyBundle) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedFormularyBundleCodeLengthRule: BatchedFormularyBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedFormularyBundle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedFormularyBundleRequiredClinicianIDRule: BatchedFormularyBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedFormularyBundle) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedFormularyBundleNameLengthRule: BatchedFormularyBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedFormularyBundle) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedFormularyBundleCodePrefixRule: BatchedFormularyBundleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedFormularyBundle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched formulary bundle.
    final class BatchedFormularyBundleValidator {
        var rules: [any BatchedFormularyBundleRule]

        init(rules: [any BatchedFormularyBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedFormularyBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedFormularyBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedFormularyBundle]) -> [String: [String]] {
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

    static func defaultBatchedFormularyBundleValidator() -> BatchedFormularyBundleValidator {
        return BatchedFormularyBundleValidator(
            rules: [
                BatchedFormularyBundleRequiredNameRule(message: "batched formulary bundle needs an entry"),
                BatchedFormularyBundleCodeLengthRule(maxLength: 86400),
                BatchedFormularyBundleRequiredClinicianIDRule(message: "batched formulary bundle needs this field"),
                BatchedFormularyBundleNameLengthRule(maxLength: 64),
                BatchedFormularyBundleCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
