import AcmePlatform
import Foundation

extension Labs {
    /// Where a pending reference range override is in its life cycle.
    enum PendingReferenceRangeOverrideStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One pending reference range override, with what the planners need to act on it.
    final class PendingReferenceRangeOverride {
        var code: String
        var label: String
        var phone: String
        var windowDays: Int
        var externalRef: String
        var minimum: Double
        var status: PendingReferenceRangeOverrideStatus

        init(code: String, label: String, phone: String, windowDays: Int, externalRef: String, minimum: Double, status: PendingReferenceRangeOverrideStatus) {
            self.code = code
            self.label = label
            self.phone = phone
            self.windowDays = windowDays
            self.externalRef = externalRef
            self.minimum = minimum
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

        func canMoveTo(_ next: PendingReferenceRangeOverrideStatus) -> Bool {
            switch status {
            case .requested:
                return next == PendingReferenceRangeOverrideStatus.granted || next == PendingReferenceRangeOverrideStatus.revoked
            case .granted:
                return next == PendingReferenceRangeOverrideStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: PendingReferenceRangeOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending reference range override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func effectiveLoad() -> Double {
            return (Double(windowDays) * minimum * 100).rounded() / 100
        }

        func copyValue() -> PendingReferenceRangeOverride {
            return PendingReferenceRangeOverride(
                code: code,
                label: label,
                phone: phone,
                windowDays: windowDays,
                externalRef: externalRef,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a pending reference range override in status requested.
    static func newPendingReferenceRangeOverride(_ code: String, label: String) -> PendingReferenceRangeOverride {
        return PendingReferenceRangeOverride(
            code: code,
            label: label,
            phone: "",
            windowDays: 0,
            externalRef: "",
            minimum: 0.0,
            status: PendingReferenceRangeOverrideStatus.requested
        )
    }
}
