import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a primary cleaning manifest is in its life cycle.
    enum PrimaryCleaningManifestStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a primary cleaning manifest and its current status.
    final class PrimaryCleaningManifest {
        var code: String
        var title: String
        var sequence: Int
        var encounterID: String
        var phone: String
        var ownerID: String
        var windowDays: Int
        var status: PrimaryCleaningManifestStatus

        init(code: String, title: String, sequence: Int, encounterID: String, phone: String, ownerID: String, windowDays: Int, status: PrimaryCleaningManifestStatus) {
            self.code = code
            self.title = title
            self.sequence = sequence
            self.encounterID = encounterID
            self.phone = phone
            self.ownerID = ownerID
            self.windowDays = windowDays
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

        func canMoveTo(_ next: PrimaryCleaningManifestStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == PrimaryCleaningManifestStatus.reopened
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

        func moveTo(_ next: PrimaryCleaningManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary cleaning manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("primary cleaning manifest") \(code)"
        }

        func adjustedTotal() -> Double {
            return (Double(windowDays) * Double(sequence) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryCleaningManifest {
            return PrimaryCleaningManifest(
                code: code,
                title: title,
                sequence: sequence,
                encounterID: encounterID,
                phone: phone,
                ownerID: ownerID,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a primary cleaning manifest in status open.
    static func newPrimaryCleaningManifest(_ code: String, title: String) -> PrimaryCleaningManifest {
        return PrimaryCleaningManifest(
            code: code,
            title: title,
            sequence: 0,
            encounterID: "",
            phone: "",
            ownerID: "",
            windowDays: 0,
            status: PrimaryCleaningManifestStatus.`open`
        )
    }
}
