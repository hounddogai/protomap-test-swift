import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a outreach rule is in its life cycle.
    enum OutreachRuleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A outreach rule. Its code is unique within a tenant.
    final class OutreachRule {
        var code: String
        var title: String
        var revision: Int
        var ward: String
        var acuity: Int
        var externalRef: String
        var version: Int
        var status: OutreachRuleStatus

        init(code: String, title: String, revision: Int, ward: String, acuity: Int, externalRef: String, version: Int, status: OutreachRuleStatus) {
            self.code = code
            self.title = title
            self.revision = revision
            self.ward = ward
            self.acuity = acuity
            self.externalRef = externalRef
            self.version = version
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: OutreachRuleStatus) -> Bool {
            switch status {
            case .`open`:
                return next == OutreachRuleStatus.resolved || next == OutreachRuleStatus.reopened
            case .inReview:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: OutreachRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("outreach rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("outreach rule") \(code)"
        }

        func adjustedLoad() -> Double {
            return ((Double(revision) + Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> OutreachRule {
            return OutreachRule(
                code: code,
                title: title,
                revision: revision,
                ward: ward,
                acuity: acuity,
                externalRef: externalRef,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a outreach rule in status open.
    static func newOutreachRule(_ code: String, title: String) -> OutreachRule {
        return OutreachRule(
            code: code,
            title: title,
            revision: 0,
            ward: "",
            acuity: 0,
            externalRef: "",
            version: 0,
            status: OutreachRuleStatus.`open`
        )
    }
}
