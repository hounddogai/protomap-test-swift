import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a lenient statement rule is in its life cycle.
    enum LenientStatementRuleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One lenient statement rule, with what the planners need to act on it.
    final class LenientStatementRule {
        var code: String
        var label: String
        var revision: Int
        var patientRef: String
        var visible: Bool
        var contactEmail: String
        var expiresAt: Int
        var endsAt: Int
        var externalRef: String
        var priority: Int
        var score: Double
        var status: LenientStatementRuleStatus

        init(code: String, label: String, revision: Int, patientRef: String, visible: Bool, contactEmail: String, expiresAt: Int, endsAt: Int, externalRef: String, priority: Int, score: Double, status: LenientStatementRuleStatus) {
            self.code = code
            self.label = label
            self.revision = revision
            self.patientRef = patientRef
            self.visible = visible
            self.contactEmail = contactEmail
            self.expiresAt = expiresAt
            self.endsAt = endsAt
            self.externalRef = externalRef
            self.priority = priority
            self.score = score
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientStatementRuleStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == LenientStatementRuleStatus.done
            case .running:
                return next == LenientStatementRuleStatus.done || next == LenientStatementRuleStatus.failed
            case .done:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientStatementRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient statement rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
            return "\("lenient statement rule") \(code)"
        }

        func effectiveValue() -> Double {
            return ((score - Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> LenientStatementRule {
            return LenientStatementRule(
                code: code,
                label: label,
                revision: revision,
                patientRef: patientRef,
                visible: visible,
                contactEmail: contactEmail,
                expiresAt: expiresAt,
                endsAt: endsAt,
                externalRef: externalRef,
                priority: priority,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a lenient statement rule in status new.
    static func newLenientStatementRule(_ code: String, label: String) -> LenientStatementRule {
        return LenientStatementRule(
            code: code,
            label: label,
            revision: 0,
            patientRef: "",
            visible: false,
            contactEmail: "",
            expiresAt: 0,
            endsAt: 0,
            externalRef: "",
            priority: 0,
            score: 0.0,
            status: LenientStatementRuleStatus.new
        )
    }
}
