import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a primary outreach entry is in its life cycle.
    enum PrimaryOutreachEntryStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A primary outreach entry as the outreach team keeps it.
    final class PrimaryOutreachEntry {
        var code: String
        var title: String
        var expiresAt: Int
        var ward: String
        var batchSize: Int
        var status: PrimaryOutreachEntryStatus

        init(code: String, title: String, expiresAt: Int, ward: String, batchSize: Int, status: PrimaryOutreachEntryStatus) {
            self.code = code
            self.title = title
            self.expiresAt = expiresAt
            self.ward = ward
            self.batchSize = batchSize
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

        func canMoveTo(_ next: PrimaryOutreachEntryStatus) -> Bool {
            switch status {
            case .`open`:
                return next == PrimaryOutreachEntryStatus.reopened
            case .inReview:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: PrimaryOutreachEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary outreach entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func adjustedTotal() -> Double {
            return (Double(expiresAt) * Double(batchSize) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryOutreachEntry {
            return PrimaryOutreachEntry(
                code: code,
                title: title,
                expiresAt: expiresAt,
                ward: ward,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a primary outreach entry in status open.
    static func newPrimaryOutreachEntry(_ code: String, title: String) -> PrimaryOutreachEntry {
        return PrimaryOutreachEntry(
            code: code,
            title: title,
            expiresAt: 0,
            ward: "",
            batchSize: 0,
            status: PrimaryOutreachEntryStatus.`open`
        )
    }
}
