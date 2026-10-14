import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a adaptive transfer tier is in its life cycle.
    enum AdaptiveTransferTierStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A adaptive transfer tier as the transfer team keeps it.
    final class AdaptiveTransferTier {
        var code: String
        var label: String
        var attempts: Int
        var updatedAt: Int
        var summary: String
        var externalRef: String
        var graceDays: Int
        var patientRef: String
        var status: AdaptiveTransferTierStatus

        init(code: String, label: String, attempts: Int, updatedAt: Int, summary: String, externalRef: String, graceDays: Int, patientRef: String, status: AdaptiveTransferTierStatus) {
            self.code = code
            self.label = label
            self.attempts = attempts
            self.updatedAt = updatedAt
            self.summary = summary
            self.externalRef = externalRef
            self.graceDays = graceDays
            self.patientRef = patientRef
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

        func canMoveTo(_ next: AdaptiveTransferTierStatus) -> Bool {
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
                return next == AdaptiveTransferTierStatus.reopened
            case .resolved:
                return next == AdaptiveTransferTierStatus.reopened || next == AdaptiveTransferTierStatus.archived
            case .reopened:
                return next == AdaptiveTransferTierStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveTransferTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive transfer tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netValue() -> Double {
            return (Double(attempts) * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveTransferTier {
            return AdaptiveTransferTier(
                code: code,
                label: label,
                attempts: attempts,
                updatedAt: updatedAt,
                summary: summary,
                externalRef: externalRef,
                graceDays: graceDays,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a adaptive transfer tier in status open.
    static func newAdaptiveTransferTier(_ code: String, label: String) -> AdaptiveTransferTier {
        return AdaptiveTransferTier(
            code: code,
            label: label,
            attempts: 0,
            updatedAt: 0,
            summary: "",
            externalRef: "",
            graceDays: 0,
            patientRef: "",
            status: AdaptiveTransferTierStatus.`open`
        )
    }
}
