import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a claim preference is in its life cycle.
    enum ClaimPreferenceStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a claim preference and its current status.
    final class ClaimPreference {
        var code: String
        var label: String
        var procedureCode: String
        var ratio: Double
        var visible: Bool
        var status: ClaimPreferenceStatus

        init(code: String, label: String, procedureCode: String, ratio: Double, visible: Bool, status: ClaimPreferenceStatus) {
            self.code = code
            self.label = label
            self.procedureCode = procedureCode
            self.ratio = ratio
            self.visible = visible
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

        func canMoveTo(_ next: ClaimPreferenceStatus) -> Bool {
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
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == ClaimPreferenceStatus.suspended || next == ClaimPreferenceStatus.closed
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

        func moveTo(_ next: ClaimPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("claim preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func measuredValue() -> Double {
            return ratio
        }

        func copyValue() -> ClaimPreference {
            return ClaimPreference(
                code: code,
                label: label,
                procedureCode: procedureCode,
                ratio: ratio,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a claim preference in status draft.
    static func newClaimPreference(_ code: String, label: String) -> ClaimPreference {
        return ClaimPreference(
            code: code,
            label: label,
            procedureCode: "",
            ratio: 0.0,
            visible: false,
            status: ClaimPreferenceStatus.draft
        )
    }
}
