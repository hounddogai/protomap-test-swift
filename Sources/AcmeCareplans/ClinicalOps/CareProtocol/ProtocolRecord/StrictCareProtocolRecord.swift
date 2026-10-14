import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a strict care protocol record is in its life cycle.
    enum StrictCareProtocolRecordStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a strict care protocol record and its current status.
    final class StrictCareProtocolRecord {
        var code: String
        var title: String
        var quantity: Int
        var approved: Bool
        var locale: String
        var contactEmail: String
        var graceDays: Int
        var specialty: String
        var updatedAt: Int
        var bed: String
        var attempts: Int
        var status: StrictCareProtocolRecordStatus

        init(code: String, title: String, quantity: Int, approved: Bool, locale: String, contactEmail: String, graceDays: Int, specialty: String, updatedAt: Int, bed: String, attempts: Int, status: StrictCareProtocolRecordStatus) {
            self.code = code
            self.title = title
            self.quantity = quantity
            self.approved = approved
            self.locale = locale
            self.contactEmail = contactEmail
            self.graceDays = graceDays
            self.specialty = specialty
            self.updatedAt = updatedAt
            self.bed = bed
            self.attempts = attempts
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StrictCareProtocolRecordStatus) -> Bool {
            switch status {
            case .created:
                return next == StrictCareProtocolRecordStatus.validated
            case .validated:
                return next == StrictCareProtocolRecordStatus.published || next == StrictCareProtocolRecordStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: StrictCareProtocolRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict care protocol record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func projectedValue() -> Double {
            return ((Double(graceDays) + Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> StrictCareProtocolRecord {
            return StrictCareProtocolRecord(
                code: code,
                title: title,
                quantity: quantity,
                approved: approved,
                locale: locale,
                contactEmail: contactEmail,
                graceDays: graceDays,
                specialty: specialty,
                updatedAt: updatedAt,
                bed: bed,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a strict care protocol record in status created.
    static func newStrictCareProtocolRecord(_ code: String, title: String) -> StrictCareProtocolRecord {
        return StrictCareProtocolRecord(
            code: code,
            title: title,
            quantity: 0,
            approved: false,
            locale: "",
            contactEmail: "",
            graceDays: 0,
            specialty: "",
            updatedAt: 0,
            bed: "",
            attempts: 0,
            status: StrictCareProtocolRecordStatus.created
        )
    }
}
