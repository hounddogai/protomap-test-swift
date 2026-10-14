import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a capped risk score claim is in its life cycle.
    enum CappedRiskScoreClaimStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A capped risk score claim. Its code is unique within a tenant.
    final class CappedRiskScoreClaim {
        var code: String
        var title: String
        var contactEmail: String
        var durationMinutes: Int
        var quantity: Int
        var category: String
        var segment: String
        var clinicianID: String
        var acuity: Int
        var status: CappedRiskScoreClaimStatus

        init(code: String, title: String, contactEmail: String, durationMinutes: Int, quantity: Int, category: String, segment: String, clinicianID: String, acuity: Int, status: CappedRiskScoreClaimStatus) {
            self.code = code
            self.title = title
            self.contactEmail = contactEmail
            self.durationMinutes = durationMinutes
            self.quantity = quantity
            self.category = category
            self.segment = segment
            self.clinicianID = clinicianID
            self.acuity = acuity
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

        func canMoveTo(_ next: CappedRiskScoreClaimStatus) -> Bool {
            switch status {
            case .idle:
                return next == CappedRiskScoreClaimStatus.warming
            case .warming:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == CappedRiskScoreClaimStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedRiskScoreClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped risk score claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func projectedTotal() -> Double {
            return ((Double(durationMinutes) - Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> CappedRiskScoreClaim {
            return CappedRiskScoreClaim(
                code: code,
                title: title,
                contactEmail: contactEmail,
                durationMinutes: durationMinutes,
                quantity: quantity,
                category: category,
                segment: segment,
                clinicianID: clinicianID,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a capped risk score claim in status idle.
    static func newCappedRiskScoreClaim(_ code: String, title: String) -> CappedRiskScoreClaim {
        return CappedRiskScoreClaim(
            code: code,
            title: title,
            contactEmail: "",
            durationMinutes: 0,
            quantity: 0,
            category: "",
            segment: "",
            clinicianID: "",
            acuity: 0,
            status: CappedRiskScoreClaimStatus.idle
        )
    }
}
