import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a pending transfer draft is in its life cycle.
    enum PendingTransferDraftStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A pending transfer draft as the transfer team keeps it.
    final class PendingTransferDraft {
        var code: String
        var label: String
        var windowDays: Int
        var patientRef: String
        var pinned: Bool
        var priority: Int
        var weight: Double
        var status: PendingTransferDraftStatus

        init(code: String, label: String, windowDays: Int, patientRef: String, pinned: Bool, priority: Int, weight: Double, status: PendingTransferDraftStatus) {
            self.code = code
            self.label = label
            self.windowDays = windowDays
            self.patientRef = patientRef
            self.pinned = pinned
            self.priority = priority
            self.weight = weight
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

        func canMoveTo(_ next: PendingTransferDraftStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == PendingTransferDraftStatus.done
            case .running:
                switch next {
                case .done:
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

        func moveTo(_ next: PendingTransferDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending transfer draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func effectiveExposure() -> Double {
            return ((weight - Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> PendingTransferDraft {
            return PendingTransferDraft(
                code: code,
                label: label,
                windowDays: windowDays,
                patientRef: patientRef,
                pinned: pinned,
                priority: priority,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a pending transfer draft in status new.
    static func newPendingTransferDraft(_ code: String, label: String) -> PendingTransferDraft {
        return PendingTransferDraft(
            code: code,
            label: label,
            windowDays: 0,
            patientRef: "",
            pinned: false,
            priority: 0,
            weight: 0.0,
            status: PendingTransferDraftStatus.new
        )
    }
}
