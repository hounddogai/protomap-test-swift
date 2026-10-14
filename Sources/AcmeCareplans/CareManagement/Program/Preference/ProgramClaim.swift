import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a program claim is in its life cycle.
    enum ProgramClaimStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One program claim, with what the planners need to act on it.
    final class ProgramClaim {
        var code: String
        var label: String
        var visible: Bool
        var segment: String
        var graceDays: Int
        var pinned: Bool
        var status: ProgramClaimStatus

        init(code: String, label: String, visible: Bool, segment: String, graceDays: Int, pinned: Bool, status: ProgramClaimStatus) {
            self.code = code
            self.label = label
            self.visible = visible
            self.segment = segment
            self.graceDays = graceDays
            self.pinned = pinned
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

        func canMoveTo(_ next: ProgramClaimStatus) -> Bool {
            switch status {
            case .draft:
                return next == ProgramClaimStatus.suspended || next == ProgramClaimStatus.closed
            case .pending:
                return next == ProgramClaimStatus.closed
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: ProgramClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("program claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("program claim") \(code)"
        }

        func measuredValue() -> Double {
            return Double(graceDays)
        }

        func copyValue() -> ProgramClaim {
            return ProgramClaim(
                code: code,
                label: label,
                visible: visible,
                segment: segment,
                graceDays: graceDays,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a program claim in status draft.
    static func newProgramClaim(_ code: String, label: String) -> ProgramClaim {
        return ProgramClaim(
            code: code,
            label: label,
            visible: false,
            segment: "",
            graceDays: 0,
            pinned: false,
            status: ProgramClaimStatus.draft
        )
    }
}
