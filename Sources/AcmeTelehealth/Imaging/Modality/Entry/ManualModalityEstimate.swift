import AcmePlatform
import Foundation

extension Imaging {
    /// Where a manual modality estimate is in its life cycle.
    enum ManualModalityEstimateStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A manual modality estimate as the modality team keeps it.
    final class ManualModalityEstimate {
        var code: String
        var label: String
        var facility: String
        var pinned: Bool
        var revision: Int
        var limit: Int
        var durationMinutes: Int
        var status: ManualModalityEstimateStatus

        init(code: String, label: String, facility: String, pinned: Bool, revision: Int, limit: Int, durationMinutes: Int, status: ManualModalityEstimateStatus) {
            self.code = code
            self.label = label
            self.facility = facility
            self.pinned = pinned
            self.revision = revision
            self.limit = limit
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: ManualModalityEstimateStatus) -> Bool {
            switch status {
            case .requested:
                return next == ManualModalityEstimateStatus.granted || next == ManualModalityEstimateStatus.revoked
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == ManualModalityEstimateStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualModalityEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual modality estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func effectiveTotal() -> Double {
            return ((Double(limit) - Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> ManualModalityEstimate {
            return ManualModalityEstimate(
                code: code,
                label: label,
                facility: facility,
                pinned: pinned,
                revision: revision,
                limit: limit,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a manual modality estimate in status requested.
    static func newManualModalityEstimate(_ code: String, label: String) -> ManualModalityEstimate {
        return ManualModalityEstimate(
            code: code,
            label: label,
            facility: "",
            pinned: false,
            revision: 0,
            limit: 0,
            durationMinutes: 0,
            status: ManualModalityEstimateStatus.requested
        )
    }
}
