import AcmePlatform
import Foundation

extension Consent {
    /// Where a primary consent form review is in its life cycle.
    enum PrimaryConsentFormReviewStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A primary consent form review. Its code is unique within a tenant.
    final class PrimaryConsentFormReview {
        var code: String
        var title: String
        var tags: [String]
        var clinicianID: String
        var graceDays: Int
        var expiresAt: Int
        var diagnosisCode: String
        var status: PrimaryConsentFormReviewStatus

        init(code: String, title: String, tags: [String], clinicianID: String, graceDays: Int, expiresAt: Int, diagnosisCode: String, status: PrimaryConsentFormReviewStatus) {
            self.code = code
            self.title = title
            self.tags = tags
            self.clinicianID = clinicianID
            self.graceDays = graceDays
            self.expiresAt = expiresAt
            self.diagnosisCode = diagnosisCode
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

        func canMoveTo(_ next: PrimaryConsentFormReviewStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == PrimaryConsentFormReviewStatus.done
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

        func moveTo(_ next: PrimaryConsentFormReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary consent form review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedValue() -> Double {
            return ((Double(expiresAt) - Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryConsentFormReview {
            return PrimaryConsentFormReview(
                code: code,
                title: title,
                tags: tags,
                clinicianID: clinicianID,
                graceDays: graceDays,
                expiresAt: expiresAt,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a primary consent form review in status new.
    static func newPrimaryConsentFormReview(_ code: String, title: String) -> PrimaryConsentFormReview {
        return PrimaryConsentFormReview(
            code: code,
            title: title,
            tags: [],
            clinicianID: "",
            graceDays: 0,
            expiresAt: 0,
            diagnosisCode: "",
            status: PrimaryConsentFormReviewStatus.new
        )
    }
}
