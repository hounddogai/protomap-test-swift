import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a census target is in its life cycle.
    enum CensusTargetStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One census target, with what the planners need to act on it.
    final class CensusTarget {
        var code: String
        var label: String
        var approved: Bool
        var contactEmail: String
        var checksum: String
        var archived: Bool
        var endsAt: Int
        var rate: Double
        var acuity: Int
        var status: CensusTargetStatus

        init(code: String, label: String, approved: Bool, contactEmail: String, checksum: String, archived: Bool, endsAt: Int, rate: Double, acuity: Int, status: CensusTargetStatus) {
            self.code = code
            self.label = label
            self.approved = approved
            self.contactEmail = contactEmail
            self.checksum = checksum
            self.archived = archived
            self.endsAt = endsAt
            self.rate = rate
            self.acuity = acuity
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

        func canMoveTo(_ next: CensusTargetStatus) -> Bool {
            switch status {
            case .`open`:
                return next == CensusTargetStatus.inReview
            case .inReview:
                return next == CensusTargetStatus.reopened
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

        func moveTo(_ next: CensusTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("census target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func netVolume() -> Double {
            return ((rate - Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> CensusTarget {
            return CensusTarget(
                code: code,
                label: label,
                approved: approved,
                contactEmail: contactEmail,
                checksum: checksum,
                archived: archived,
                endsAt: endsAt,
                rate: rate,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a census target in status open.
    static func newCensusTarget(_ code: String, label: String) -> CensusTarget {
        return CensusTarget(
            code: code,
            label: label,
            approved: false,
            contactEmail: "",
            checksum: "",
            archived: false,
            endsAt: 0,
            rate: 0.0,
            acuity: 0,
            status: CensusTargetStatus.`open`
        )
    }
}
