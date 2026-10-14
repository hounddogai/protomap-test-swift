import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a outreach entry is in its life cycle.
    enum OutreachEntryStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a outreach entry and its current status.
    final class OutreachEntry {
        var code: String
        var title: String
        var threshold: Double
        var clinicianID: String
        var floorValue: Double
        var status: OutreachEntryStatus

        init(code: String, title: String, threshold: Double, clinicianID: String, floorValue: Double, status: OutreachEntryStatus) {
            self.code = code
            self.title = title
            self.threshold = threshold
            self.clinicianID = clinicianID
            self.floorValue = floorValue
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: OutreachEntryStatus) -> Bool {
            switch status {
            case .proposed:
                return next == OutreachEntryStatus.rejected
            case .approved:
                return next == OutreachEntryStatus.withdrawn
            case .rejected:
                return next == OutreachEntryStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: OutreachEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("outreach entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func effectiveExposure() -> Double {
            return (threshold * floorValue * 100).rounded() / 100
        }

        func copyValue() -> OutreachEntry {
            return OutreachEntry(
                code: code,
                title: title,
                threshold: threshold,
                clinicianID: clinicianID,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a outreach entry in status proposed.
    static func newOutreachEntry(_ code: String, title: String) -> OutreachEntry {
        return OutreachEntry(
            code: code,
            title: title,
            threshold: 0.0,
            clinicianID: "",
            floorValue: 0.0,
            status: OutreachEntryStatus.proposed
        )
    }
}
