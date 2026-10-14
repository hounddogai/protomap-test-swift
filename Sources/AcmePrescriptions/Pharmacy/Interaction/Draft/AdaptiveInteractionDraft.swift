import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a adaptive interaction draft is in its life cycle.
    enum AdaptiveInteractionDraftStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A adaptive interaction draft. Its code is unique within a tenant.
    final class AdaptiveInteractionDraft {
        var code: String
        var label: String
        var visitMinutes: Int
        var expiresAt: Int
        var sequence: Int
        var minimum: Double
        var priority: Int
        var archived: Bool
        var status: AdaptiveInteractionDraftStatus

        init(code: String, label: String, visitMinutes: Int, expiresAt: Int, sequence: Int, minimum: Double, priority: Int, archived: Bool, status: AdaptiveInteractionDraftStatus) {
            self.code = code
            self.label = label
            self.visitMinutes = visitMinutes
            self.expiresAt = expiresAt
            self.sequence = sequence
            self.minimum = minimum
            self.priority = priority
            self.archived = archived
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

        func canMoveTo(_ next: AdaptiveInteractionDraftStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == AdaptiveInteractionDraftStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveInteractionDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive interaction draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netVolume() -> Double {
            return ((Double(expiresAt) - minimum) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveInteractionDraft {
            return AdaptiveInteractionDraft(
                code: code,
                label: label,
                visitMinutes: visitMinutes,
                expiresAt: expiresAt,
                sequence: sequence,
                minimum: minimum,
                priority: priority,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a adaptive interaction draft in status new.
    static func newAdaptiveInteractionDraft(_ code: String, label: String) -> AdaptiveInteractionDraft {
        return AdaptiveInteractionDraft(
            code: code,
            label: label,
            visitMinutes: 0,
            expiresAt: 0,
            sequence: 0,
            minimum: 0.0,
            priority: 0,
            archived: false,
            status: AdaptiveInteractionDraftStatus.new
        )
    }
}
