import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a primary order set draft must pass. Check returns its problems, or none.
    protocol PrimaryOrderSetDraftRule {
        func check(_ item: PrimaryOrderSetDraft) -> [String]
    }

    final class PrimaryOrderSetDraftAllowedPatientRefRule: PrimaryOrderSetDraftRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimaryOrderSetDraft) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.patientRef)) {
                return ["patient ref \(item.patientRef) is expired"]
            }
            return []
        }
    }

    final class PrimaryOrderSetDraftApprovedGuardRule: PrimaryOrderSetDraftRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: PrimaryOrderSetDraft) -> [String] {
            if item.approved && (item.margin > limit) {
                return ["margin \(item.margin) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class PrimaryOrderSetDraftCodePrefixRule: PrimaryOrderSetDraftRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimaryOrderSetDraft) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary order set draft.
    final class PrimaryOrderSetDraftValidator {
        var rules: [any PrimaryOrderSetDraftRule]

        init(rules: [any PrimaryOrderSetDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryOrderSetDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryOrderSetDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryOrderSetDraft]) -> [String: [String]] {
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

    static func defaultPrimaryOrderSetDraftValidator() -> PrimaryOrderSetDraftValidator {
        return PrimaryOrderSetDraftValidator(
            rules: [
                PrimaryOrderSetDraftAllowedPatientRefRule(allowed: ["primary", "pending", "adaptive"]),
                PrimaryOrderSetDraftApprovedGuardRule(limit: 7.1),
                PrimaryOrderSetDraftCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
