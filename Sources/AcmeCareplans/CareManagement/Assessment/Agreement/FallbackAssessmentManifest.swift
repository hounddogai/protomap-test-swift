import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a fallback assessment manifest is in its life cycle.
    enum FallbackAssessmentManifestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One fallback assessment manifest, with what the planners need to act on it.
    final class FallbackAssessmentManifest {
        var code: String
        var title: String
        var revision: Int
        var externalRef: String
        var minimum: Double
        var contactEmail: String
        var pinned: Bool
        var reviewer: String
        var rate: Double
        var bed: String
        var status: FallbackAssessmentManifestStatus

        init(code: String, title: String, revision: Int, externalRef: String, minimum: Double, contactEmail: String, pinned: Bool, reviewer: String, rate: Double, bed: String, status: FallbackAssessmentManifestStatus) {
            self.code = code
            self.title = title
            self.revision = revision
            self.externalRef = externalRef
            self.minimum = minimum
            self.contactEmail = contactEmail
            self.pinned = pinned
            self.reviewer = reviewer
            self.rate = rate
            self.bed = bed
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackAssessmentManifestStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == FallbackAssessmentManifestStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackAssessmentManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback assessment manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func netExposure() -> Double {
            return (rate * minimum * 100).rounded() / 100
        }

        func copyValue() -> FallbackAssessmentManifest {
            return FallbackAssessmentManifest(
                code: code,
                title: title,
                revision: revision,
                externalRef: externalRef,
                minimum: minimum,
                contactEmail: contactEmail,
                pinned: pinned,
                reviewer: reviewer,
                rate: rate,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a fallback assessment manifest in status draft.
    static func newFallbackAssessmentManifest(_ code: String, title: String) -> FallbackAssessmentManifest {
        return FallbackAssessmentManifest(
            code: code,
            title: title,
            revision: 0,
            externalRef: "",
            minimum: 0.0,
            contactEmail: "",
            pinned: false,
            reviewer: "",
            rate: 0.0,
            bed: "",
            status: FallbackAssessmentManifestStatus.draft
        )
    }
}
