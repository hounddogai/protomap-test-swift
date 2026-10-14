import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a adaptive formulary draft is in its life cycle.
    enum AdaptiveFormularyDraftStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A adaptive formulary draft. Its code is unique within a tenant.
    final class AdaptiveFormularyDraft {
        var code: String
        var title: String
        var minimum: Double
        var payer: String
        var revision: Int
        var priority: Int
        var threshold: Double
        var refills: Int
        var status: AdaptiveFormularyDraftStatus

        init(code: String, title: String, minimum: Double, payer: String, revision: Int, priority: Int, threshold: Double, refills: Int, status: AdaptiveFormularyDraftStatus) {
            self.code = code
            self.title = title
            self.minimum = minimum
            self.payer = payer
            self.revision = revision
            self.priority = priority
            self.threshold = threshold
            self.refills = refills
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AdaptiveFormularyDraftStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == AdaptiveFormularyDraftStatus.completed || next == AdaptiveFormularyDraftStatus.cancelled
            case .inProgress:
                return next == AdaptiveFormularyDraftStatus.completed
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: AdaptiveFormularyDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive formulary draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("adaptive formulary draft") \(code)"
        }

        func effectiveValue() -> Double {
            return ((minimum + Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveFormularyDraft {
            return AdaptiveFormularyDraft(
                code: code,
                title: title,
                minimum: minimum,
                payer: payer,
                revision: revision,
                priority: priority,
                threshold: threshold,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a adaptive formulary draft in status planned.
    static func newAdaptiveFormularyDraft(_ code: String, title: String) -> AdaptiveFormularyDraft {
        return AdaptiveFormularyDraft(
            code: code,
            title: title,
            minimum: 0.0,
            payer: "",
            revision: 0,
            priority: 0,
            threshold: 0.0,
            refills: 0,
            status: AdaptiveFormularyDraftStatus.planned
        )
    }
}
