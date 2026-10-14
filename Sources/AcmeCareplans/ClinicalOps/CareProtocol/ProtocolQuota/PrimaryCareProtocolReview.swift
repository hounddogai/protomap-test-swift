import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a primary care protocol review is in its life cycle.
    enum PrimaryCareProtocolReviewStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One primary care protocol review, with what the planners need to act on it.
    final class PrimaryCareProtocolReview {
        var code: String
        var title: String
        var acuity: Int
        var createdAt: Int
        var visitMinutes: Int
        var checksum: String
        var version: Int
        var sequence: Int
        var revision: Int
        var contactEmail: String
        var endsAt: Int
        var status: PrimaryCareProtocolReviewStatus

        init(code: String, title: String, acuity: Int, createdAt: Int, visitMinutes: Int, checksum: String, version: Int, sequence: Int, revision: Int, contactEmail: String, endsAt: Int, status: PrimaryCareProtocolReviewStatus) {
            self.code = code
            self.title = title
            self.acuity = acuity
            self.createdAt = createdAt
            self.visitMinutes = visitMinutes
            self.checksum = checksum
            self.version = version
            self.sequence = sequence
            self.revision = revision
            self.contactEmail = contactEmail
            self.endsAt = endsAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PrimaryCareProtocolReviewStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: PrimaryCareProtocolReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary care protocol review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func adjustedExposure() -> Double {
            return ((Double(createdAt) - Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryCareProtocolReview {
            return PrimaryCareProtocolReview(
                code: code,
                title: title,
                acuity: acuity,
                createdAt: createdAt,
                visitMinutes: visitMinutes,
                checksum: checksum,
                version: version,
                sequence: sequence,
                revision: revision,
                contactEmail: contactEmail,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a primary care protocol review in status requested.
    static func newPrimaryCareProtocolReview(_ code: String, title: String) -> PrimaryCareProtocolReview {
        return PrimaryCareProtocolReview(
            code: code,
            title: title,
            acuity: 0,
            createdAt: 0,
            visitMinutes: 0,
            checksum: "",
            version: 0,
            sequence: 0,
            revision: 0,
            contactEmail: "",
            endsAt: 0,
            status: PrimaryCareProtocolReviewStatus.requested
        )
    }
}
