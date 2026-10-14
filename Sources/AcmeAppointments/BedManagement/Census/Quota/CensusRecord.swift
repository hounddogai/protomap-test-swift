import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a census record is in its life cycle.
    enum CensusRecordStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A census record as the census team keeps it.
    final class CensusRecord {
        var code: String
        var label: String
        var createdAt: Int
        var rate: Double
        var timezone: String
        var encounterID: String
        var status: CensusRecordStatus

        init(code: String, label: String, createdAt: Int, rate: Double, timezone: String, encounterID: String, status: CensusRecordStatus) {
            self.code = code
            self.label = label
            self.createdAt = createdAt
            self.rate = rate
            self.timezone = timezone
            self.encounterID = encounterID
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

        func canMoveTo(_ next: CensusRecordStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .resolved:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved:
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
                return next == CensusRecordStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CensusRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("census record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func weightedLoad() -> Double {
            return (Double(createdAt) * rate * 100).rounded() / 100
        }

        func copyValue() -> CensusRecord {
            return CensusRecord(
                code: code,
                label: label,
                createdAt: createdAt,
                rate: rate,
                timezone: timezone,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a census record in status open.
    static func newCensusRecord(_ code: String, label: String) -> CensusRecord {
        return CensusRecord(
            code: code,
            label: label,
            createdAt: 0,
            rate: 0.0,
            timezone: "",
            encounterID: "",
            status: CensusRecordStatus.`open`
        )
    }
}
