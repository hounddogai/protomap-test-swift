import AcmePlatform
import Foundation

extension Imaging {
    /// Where a primary care protocol score is in its life cycle.
    enum PrimaryCareProtocolScoreStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a primary care protocol score and its current status.
    final class PrimaryCareProtocolScore {
        var code: String
        var name: String
        var title: String
        var timezone: String
        var clinicianID: String
        var encounterID: String
        var checksum: String
        var approved: Bool
        var facility: String
        var endsAt: Int
        var status: PrimaryCareProtocolScoreStatus

        init(code: String, name: String, title: String, timezone: String, clinicianID: String, encounterID: String, checksum: String, approved: Bool, facility: String, endsAt: Int, status: PrimaryCareProtocolScoreStatus) {
            self.code = code
            self.name = name
            self.title = title
            self.timezone = timezone
            self.clinicianID = clinicianID
            self.encounterID = encounterID
            self.checksum = checksum
            self.approved = approved
            self.facility = facility
            self.endsAt = endsAt
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

        func canMoveTo(_ next: PrimaryCareProtocolScoreStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == PrimaryCareProtocolScoreStatus.reopened || next == PrimaryCareProtocolScoreStatus.archived
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

        func moveTo(_ next: PrimaryCareProtocolScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary care protocol score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func measuredValue() -> Double {
            return Double(endsAt)
        }

        func copyValue() -> PrimaryCareProtocolScore {
            return PrimaryCareProtocolScore(
                code: code,
                name: name,
                title: title,
                timezone: timezone,
                clinicianID: clinicianID,
                encounterID: encounterID,
                checksum: checksum,
                approved: approved,
                facility: facility,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a primary care protocol score in status open.
    static func newPrimaryCareProtocolScore(_ code: String, name: String) -> PrimaryCareProtocolScore {
        return PrimaryCareProtocolScore(
            code: code,
            name: name,
            title: "",
            timezone: "",
            clinicianID: "",
            encounterID: "",
            checksum: "",
            approved: false,
            facility: "",
            endsAt: 0,
            status: PrimaryCareProtocolScoreStatus.`open`
        )
    }
}
