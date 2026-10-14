import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a care protocol notice is in its life cycle.
    enum CareProtocolNoticeStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A care protocol notice. Its code is unique within a tenant.
    final class CareProtocolNotice {
        var code: String
        var title: String
        var minimum: Double
        var revision: Int
        var approved: Bool
        var sequence: Int
        var description: String
        var dosageMg: Double
        var clinicianID: String
        var startsAt: Int
        var status: CareProtocolNoticeStatus

        init(code: String, title: String, minimum: Double, revision: Int, approved: Bool, sequence: Int, description: String, dosageMg: Double, clinicianID: String, startsAt: Int, status: CareProtocolNoticeStatus) {
            self.code = code
            self.title = title
            self.minimum = minimum
            self.revision = revision
            self.approved = approved
            self.sequence = sequence
            self.description = description
            self.dosageMg = dosageMg
            self.clinicianID = clinicianID
            self.startsAt = startsAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CareProtocolNoticeStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == CareProtocolNoticeStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: CareProtocolNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func weightedTotal() -> Double {
            return ((minimum + Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolNotice {
            return CareProtocolNotice(
                code: code,
                title: title,
                minimum: minimum,
                revision: revision,
                approved: approved,
                sequence: sequence,
                description: description,
                dosageMg: dosageMg,
                clinicianID: clinicianID,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a care protocol notice in status idle.
    static func newCareProtocolNotice(_ code: String, title: String) -> CareProtocolNotice {
        return CareProtocolNotice(
            code: code,
            title: title,
            minimum: 0.0,
            revision: 0,
            approved: false,
            sequence: 0,
            description: "",
            dosageMg: 0.0,
            clinicianID: "",
            startsAt: 0,
            status: CareProtocolNoticeStatus.idle
        )
    }
}
