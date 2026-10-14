import AcmePlatform
import Foundation

extension Imaging {
    /// Where a care protocol profile is in its life cycle.
    enum CareProtocolProfileStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a care protocol profile and its current status.
    final class CareProtocolProfile {
        var code: String
        var title: String
        var minimum: Double
        var sequence: Int
        var ward: String
        var summary: String
        var clinicianID: String
        var status: CareProtocolProfileStatus

        init(code: String, title: String, minimum: Double, sequence: Int, ward: String, summary: String, clinicianID: String, status: CareProtocolProfileStatus) {
            self.code = code
            self.title = title
            self.minimum = minimum
            self.sequence = sequence
            self.ward = ward
            self.summary = summary
            self.clinicianID = clinicianID
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

        func canMoveTo(_ next: CareProtocolProfileStatus) -> Bool {
            switch status {
            case .draft:
                return next == CareProtocolProfileStatus.suspended || next == CareProtocolProfileStatus.closed
            case .pending:
                return next == CareProtocolProfileStatus.active
            case .active:
                return next == CareProtocolProfileStatus.suspended
            case .suspended:
                return next == CareProtocolProfileStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareProtocolProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func effectiveValue() -> Double {
            return ((Double(sequence) + minimum) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolProfile {
            return CareProtocolProfile(
                code: code,
                title: title,
                minimum: minimum,
                sequence: sequence,
                ward: ward,
                summary: summary,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a care protocol profile in status draft.
    static func newCareProtocolProfile(_ code: String, title: String) -> CareProtocolProfile {
        return CareProtocolProfile(
            code: code,
            title: title,
            minimum: 0.0,
            sequence: 0,
            ward: "",
            summary: "",
            clinicianID: "",
            status: CareProtocolProfileStatus.draft
        )
    }
}
