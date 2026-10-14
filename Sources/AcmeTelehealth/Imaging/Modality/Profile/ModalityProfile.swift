import AcmePlatform
import Foundation

extension Imaging {
    /// Where a modality profile is in its life cycle.
    enum ModalityProfileStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A modality profile as the modality team keeps it.
    final class ModalityProfile {
        var code: String
        var title: String
        var createdAt: Int
        var clinicianID: String
        var bed: String
        var contactEmail: String
        var procedureCode: String
        var ceiling: Double
        var expiresAt: Int
        var status: ModalityProfileStatus

        init(code: String, title: String, createdAt: Int, clinicianID: String, bed: String, contactEmail: String, procedureCode: String, ceiling: Double, expiresAt: Int, status: ModalityProfileStatus) {
            self.code = code
            self.title = title
            self.createdAt = createdAt
            self.clinicianID = clinicianID
            self.bed = bed
            self.contactEmail = contactEmail
            self.procedureCode = procedureCode
            self.ceiling = ceiling
            self.expiresAt = expiresAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ModalityProfileStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == ModalityProfileStatus.cancelled
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: ModalityProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("modality profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("modality profile") \(code)"
        }

        func weightedLoad() -> Double {
            return ((Double(expiresAt) - ceiling) * 100).rounded() / 100
        }

        func copyValue() -> ModalityProfile {
            return ModalityProfile(
                code: code,
                title: title,
                createdAt: createdAt,
                clinicianID: clinicianID,
                bed: bed,
                contactEmail: contactEmail,
                procedureCode: procedureCode,
                ceiling: ceiling,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a modality profile in status planned.
    static func newModalityProfile(_ code: String, title: String) -> ModalityProfile {
        return ModalityProfile(
            code: code,
            title: title,
            createdAt: 0,
            clinicianID: "",
            bed: "",
            contactEmail: "",
            procedureCode: "",
            ceiling: 0.0,
            expiresAt: 0,
            status: ModalityProfileStatus.planned
        )
    }
}
