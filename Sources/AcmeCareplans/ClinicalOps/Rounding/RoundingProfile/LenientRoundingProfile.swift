import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a lenient rounding profile is in its life cycle.
    enum LenientRoundingProfileStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A lenient rounding profile. Its code is unique within a tenant.
    final class LenientRoundingProfile {
        var code: String
        var name: String
        var facility: String
        var threshold: Double
        var approved: Bool
        var phone: String
        var updatedAt: Int
        var description: String
        var quantity: Int
        var status: LenientRoundingProfileStatus

        init(code: String, name: String, facility: String, threshold: Double, approved: Bool, phone: String, updatedAt: Int, description: String, quantity: Int, status: LenientRoundingProfileStatus) {
            self.code = code
            self.name = name
            self.facility = facility
            self.threshold = threshold
            self.approved = approved
            self.phone = phone
            self.updatedAt = updatedAt
            self.description = description
            self.quantity = quantity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientRoundingProfileStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == LenientRoundingProfileStatus.active || next == LenientRoundingProfileStatus.closed
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == LenientRoundingProfileStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientRoundingProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient rounding profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("lenient rounding profile") \(code)"
        }

        func adjustedExposure() -> Double {
            return ((threshold - Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> LenientRoundingProfile {
            return LenientRoundingProfile(
                code: code,
                name: name,
                facility: facility,
                threshold: threshold,
                approved: approved,
                phone: phone,
                updatedAt: updatedAt,
                description: description,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a lenient rounding profile in status draft.
    static func newLenientRoundingProfile(_ code: String, name: String) -> LenientRoundingProfile {
        return LenientRoundingProfile(
            code: code,
            name: name,
            facility: "",
            threshold: 0.0,
            approved: false,
            phone: "",
            updatedAt: 0,
            description: "",
            quantity: 0,
            status: LenientRoundingProfileStatus.draft
        )
    }
}
