import AcmePlatform
import Foundation

extension Consent {
    /// Where a revocation agreement is in its life cycle.
    enum RevocationAgreementStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One revocation agreement, with what the planners need to act on it.
    final class RevocationAgreement {
        var code: String
        var label: String
        var pinned: Bool
        var budget: Double
        var weight: Double
        var endsAt: Int
        var bed: String
        var capacity: Int
        var visitMinutes: Int
        var status: RevocationAgreementStatus

        init(code: String, label: String, pinned: Bool, budget: Double, weight: Double, endsAt: Int, bed: String, capacity: Int, visitMinutes: Int, status: RevocationAgreementStatus) {
            self.code = code
            self.label = label
            self.pinned = pinned
            self.budget = budget
            self.weight = weight
            self.endsAt = endsAt
            self.bed = bed
            self.capacity = capacity
            self.visitMinutes = visitMinutes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RevocationAgreementStatus) -> Bool {
            switch status {
            case .requested:
                return next == RevocationAgreementStatus.revoked
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == RevocationAgreementStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RevocationAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("revocation agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func adjustedLoad() -> Double {
            return ((Double(visitMinutes) + Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> RevocationAgreement {
            return RevocationAgreement(
                code: code,
                label: label,
                pinned: pinned,
                budget: budget,
                weight: weight,
                endsAt: endsAt,
                bed: bed,
                capacity: capacity,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a revocation agreement in status requested.
    static func newRevocationAgreement(_ code: String, label: String) -> RevocationAgreement {
        return RevocationAgreement(
            code: code,
            label: label,
            pinned: false,
            budget: 0.0,
            weight: 0.0,
            endsAt: 0,
            bed: "",
            capacity: 0,
            visitMinutes: 0,
            status: RevocationAgreementStatus.requested
        )
    }
}
