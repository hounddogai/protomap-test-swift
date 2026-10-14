import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a outreach review is in its life cycle.
    enum OutreachReviewStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a outreach review and its current status.
    final class OutreachReview {
        var code: String
        var title: String
        var revision: Int
        var category: String
        var pinned: Bool
        var clinicianID: String
        var updatedAt: Int
        var country: String
        var reviewer: String
        var refills: Int
        var description: String
        var status: OutreachReviewStatus

        init(code: String, title: String, revision: Int, category: String, pinned: Bool, clinicianID: String, updatedAt: Int, country: String, reviewer: String, refills: Int, description: String, status: OutreachReviewStatus) {
            self.code = code
            self.title = title
            self.revision = revision
            self.category = category
            self.pinned = pinned
            self.clinicianID = clinicianID
            self.updatedAt = updatedAt
            self.country = country
            self.reviewer = reviewer
            self.refills = refills
            self.description = description
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

        func canMoveTo(_ next: OutreachReviewStatus) -> Bool {
            switch status {
            case .idle:
                return next == OutreachReviewStatus.ready || next == OutreachReviewStatus.draining
            case .warming:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == OutreachReviewStatus.draining
            case .draining:
                return next == OutreachReviewStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: OutreachReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("outreach review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\("outreach review") \(code)"
        }

        func weightedVolume() -> Double {
            return ((Double(updatedAt) - Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> OutreachReview {
            return OutreachReview(
                code: code,
                title: title,
                revision: revision,
                category: category,
                pinned: pinned,
                clinicianID: clinicianID,
                updatedAt: updatedAt,
                country: country,
                reviewer: reviewer,
                refills: refills,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a outreach review in status idle.
    static func newOutreachReview(_ code: String, title: String) -> OutreachReview {
        return OutreachReview(
            code: code,
            title: title,
            revision: 0,
            category: "",
            pinned: false,
            clinicianID: "",
            updatedAt: 0,
            country: "",
            reviewer: "",
            refills: 0,
            description: "",
            status: OutreachReviewStatus.idle
        )
    }
}
