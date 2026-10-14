import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a care gap agreement is in its life cycle.
    enum CareGapAgreementStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a care gap agreement and its current status.
    final class CareGapAgreement {
        var code: String
        var title: String
        var specialty: String
        var createdAt: Int
        var acuity: Int
        var archived: Bool
        var visible: Bool
        var ceiling: Double
        var status: CareGapAgreementStatus

        init(code: String, title: String, specialty: String, createdAt: Int, acuity: Int, archived: Bool, visible: Bool, ceiling: Double, status: CareGapAgreementStatus) {
            self.code = code
            self.title = title
            self.specialty = specialty
            self.createdAt = createdAt
            self.acuity = acuity
            self.archived = archived
            self.visible = visible
            self.ceiling = ceiling
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

        func canMoveTo(_ next: CareGapAgreementStatus) -> Bool {
            switch status {
            case .requested:
                return next == CareGapAgreementStatus.revoked || next == CareGapAgreementStatus.expired
            case .granted:
                return next == CareGapAgreementStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: CareGapAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care gap agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func effectiveVolume() -> Double {
            return ((Double(acuity) + Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> CareGapAgreement {
            return CareGapAgreement(
                code: code,
                title: title,
                specialty: specialty,
                createdAt: createdAt,
                acuity: acuity,
                archived: archived,
                visible: visible,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a care gap agreement in status requested.
    static func newCareGapAgreement(_ code: String, title: String) -> CareGapAgreement {
        return CareGapAgreement(
            code: code,
            title: title,
            specialty: "",
            createdAt: 0,
            acuity: 0,
            archived: false,
            visible: false,
            ceiling: 0.0,
            status: CareGapAgreementStatus.requested
        )
    }
}
