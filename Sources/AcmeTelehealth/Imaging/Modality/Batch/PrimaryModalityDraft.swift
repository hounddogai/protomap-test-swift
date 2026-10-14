import AcmePlatform
import Foundation

extension Imaging {
    /// Where a primary modality draft is in its life cycle.
    enum PrimaryModalityDraftStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One primary modality draft, with what the planners need to act on it.
    final class PrimaryModalityDraft {
        var code: String
        var label: String
        var refills: Int
        var region: String
        var revision: Int
        var externalRef: String
        var attempts: Int
        var weight: Double
        var endsAt: Int
        var status: PrimaryModalityDraftStatus

        init(code: String, label: String, refills: Int, region: String, revision: Int, externalRef: String, attempts: Int, weight: Double, endsAt: Int, status: PrimaryModalityDraftStatus) {
            self.code = code
            self.label = label
            self.refills = refills
            self.region = region
            self.revision = revision
            self.externalRef = externalRef
            self.attempts = attempts
            self.weight = weight
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

        func canMoveTo(_ next: PrimaryModalityDraftStatus) -> Bool {
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
                return next == PrimaryModalityDraftStatus.archived
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == PrimaryModalityDraftStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryModalityDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary modality draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netExposure() -> Double {
            return ((Double(endsAt) - Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryModalityDraft {
            return PrimaryModalityDraft(
                code: code,
                label: label,
                refills: refills,
                region: region,
                revision: revision,
                externalRef: externalRef,
                attempts: attempts,
                weight: weight,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a primary modality draft in status open.
    static func newPrimaryModalityDraft(_ code: String, label: String) -> PrimaryModalityDraft {
        return PrimaryModalityDraft(
            code: code,
            label: label,
            refills: 0,
            region: "",
            revision: 0,
            externalRef: "",
            attempts: 0,
            weight: 0.0,
            endsAt: 0,
            status: PrimaryModalityDraftStatus.`open`
        )
    }
}
