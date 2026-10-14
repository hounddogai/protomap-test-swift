import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a care gap audit is in its life cycle.
    enum CareGapAuditStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One care gap audit, with what the planners need to act on it.
    final class CareGapAudit {
        var code: String
        var label: String
        var phone: String
        var expiresAt: Int
        var allergy: String
        var priority: Int
        var status: CareGapAuditStatus

        init(code: String, label: String, phone: String, expiresAt: Int, allergy: String, priority: Int, status: CareGapAuditStatus) {
            self.code = code
            self.label = label
            self.phone = phone
            self.expiresAt = expiresAt
            self.allergy = allergy
            self.priority = priority
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

        func canMoveTo(_ next: CareGapAuditStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .archived:
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
                return next == CareGapAuditStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareGapAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care gap audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func weightedTotal() -> Double {
            return ((Double(priority) - Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> CareGapAudit {
            return CareGapAudit(
                code: code,
                label: label,
                phone: phone,
                expiresAt: expiresAt,
                allergy: allergy,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a care gap audit in status open.
    static func newCareGapAudit(_ code: String, label: String) -> CareGapAudit {
        return CareGapAudit(
            code: code,
            label: label,
            phone: "",
            expiresAt: 0,
            allergy: "",
            priority: 0,
            status: CareGapAuditStatus.`open`
        )
    }
}
