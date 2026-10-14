import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a substitution quota is in its life cycle.
    enum SubstitutionQuotaStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a substitution quota and its current status.
    final class SubstitutionQuota {
        var code: String
        var label: String
        var endsAt: Int
        var ceiling: Double
        var expiresAt: Int
        var limit: Int
        var phone: String
        var patientRef: String
        var status: SubstitutionQuotaStatus

        init(code: String, label: String, endsAt: Int, ceiling: Double, expiresAt: Int, limit: Int, phone: String, patientRef: String, status: SubstitutionQuotaStatus) {
            self.code = code
            self.label = label
            self.endsAt = endsAt
            self.ceiling = ceiling
            self.expiresAt = expiresAt
            self.limit = limit
            self.phone = phone
            self.patientRef = patientRef
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SubstitutionQuotaStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == SubstitutionQuotaStatus.draining
            case .ready:
                return next == SubstitutionQuotaStatus.draining
            case .draining:
                return next == SubstitutionQuotaStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SubstitutionQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("substitution quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func projectedLoad() -> Double {
            return (Double(endsAt) * Double(limit) * 100).rounded() / 100
        }

        func copyValue() -> SubstitutionQuota {
            return SubstitutionQuota(
                code: code,
                label: label,
                endsAt: endsAt,
                ceiling: ceiling,
                expiresAt: expiresAt,
                limit: limit,
                phone: phone,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a substitution quota in status idle.
    static func newSubstitutionQuota(_ code: String, label: String) -> SubstitutionQuota {
        return SubstitutionQuota(
            code: code,
            label: label,
            endsAt: 0,
            ceiling: 0.0,
            expiresAt: 0,
            limit: 0,
            phone: "",
            patientRef: "",
            status: SubstitutionQuotaStatus.idle
        )
    }
}
