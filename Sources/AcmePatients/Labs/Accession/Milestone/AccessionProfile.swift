import AcmePlatform
import Foundation

extension Labs {
    /// Where a accession profile is in its life cycle.
    enum AccessionProfileStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One accession profile, with what the planners need to act on it.
    final class AccessionProfile {
        var code: String
        var label: String
        var durationMinutes: Int
        var weight: Double
        var copay: Double
        var status: AccessionProfileStatus

        init(code: String, label: String, durationMinutes: Int, weight: Double, copay: Double, status: AccessionProfileStatus) {
            self.code = code
            self.label = label
            self.durationMinutes = durationMinutes
            self.weight = weight
            self.copay = copay
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AccessionProfileStatus) -> Bool {
            switch status {
            case .created:
                return next == AccessionProfileStatus.published
            case .validated:
                return next == AccessionProfileStatus.published
            case .published:
                return next == AccessionProfileStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AccessionProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("accession profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func effectiveExposure() -> Double {
            return ((weight + copay) * 100).rounded() / 100
        }

        func copyValue() -> AccessionProfile {
            return AccessionProfile(
                code: code,
                label: label,
                durationMinutes: durationMinutes,
                weight: weight,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a accession profile in status created.
    static func newAccessionProfile(_ code: String, label: String) -> AccessionProfile {
        return AccessionProfile(
            code: code,
            label: label,
            durationMinutes: 0,
            weight: 0.0,
            copay: 0.0,
            status: AccessionProfileStatus.created
        )
    }
}
