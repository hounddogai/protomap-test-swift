import AcmePlatform
import Foundation

extension Staffing {
    /// Where a primary credential review is in its life cycle.
    enum PrimaryCredentialReviewStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A primary credential review as the credential team keeps it.
    final class PrimaryCredentialReview {
        var code: String
        var label: String
        var startsAt: Int
        var contactEmail: String
        var refills: Int
        var visible: Bool
        var endsAt: Int
        var updatedAt: Int
        var createdAt: Int
        var region: String
        var tags: [String]
        var status: PrimaryCredentialReviewStatus

        init(code: String, label: String, startsAt: Int, contactEmail: String, refills: Int, visible: Bool, endsAt: Int, updatedAt: Int, createdAt: Int, region: String, tags: [String], status: PrimaryCredentialReviewStatus) {
            self.code = code
            self.label = label
            self.startsAt = startsAt
            self.contactEmail = contactEmail
            self.refills = refills
            self.visible = visible
            self.endsAt = endsAt
            self.updatedAt = updatedAt
            self.createdAt = createdAt
            self.region = region
            self.tags = tags
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PrimaryCredentialReviewStatus) -> Bool {
            switch status {
            case .new:
                return next == PrimaryCredentialReviewStatus.running || next == PrimaryCredentialReviewStatus.done
            case .queued:
                return next == PrimaryCredentialReviewStatus.done || next == PrimaryCredentialReviewStatus.failed
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: PrimaryCredentialReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary credential review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("primary credential review") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedTotal() -> Double {
            return ((Double(refills) + Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryCredentialReview {
            return PrimaryCredentialReview(
                code: code,
                label: label,
                startsAt: startsAt,
                contactEmail: contactEmail,
                refills: refills,
                visible: visible,
                endsAt: endsAt,
                updatedAt: updatedAt,
                createdAt: createdAt,
                region: region,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a primary credential review in status new.
    static func newPrimaryCredentialReview(_ code: String, label: String) -> PrimaryCredentialReview {
        return PrimaryCredentialReview(
            code: code,
            label: label,
            startsAt: 0,
            contactEmail: "",
            refills: 0,
            visible: false,
            endsAt: 0,
            updatedAt: 0,
            createdAt: 0,
            region: "",
            tags: [],
            status: PrimaryCredentialReviewStatus.new
        )
    }
}
