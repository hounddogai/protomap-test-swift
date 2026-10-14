import AcmePlatform
import Foundation

extension Consent {
    /// Where a witness profile is in its life cycle.
    enum WitnessProfileStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A witness profile. Its code is unique within a tenant.
    final class WitnessProfile {
        var code: String
        var label: String
        var windowDays: Int
        var phone: String
        var createdAt: Int
        var segment: String
        var timezone: String
        var status: WitnessProfileStatus

        init(code: String, label: String, windowDays: Int, phone: String, createdAt: Int, segment: String, timezone: String, status: WitnessProfileStatus) {
            self.code = code
            self.label = label
            self.windowDays = windowDays
            self.phone = phone
            self.createdAt = createdAt
            self.segment = segment
            self.timezone = timezone
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

        func canMoveTo(_ next: WitnessProfileStatus) -> Bool {
            switch status {
            case .draft:
                return next == WitnessProfileStatus.active
            case .pending:
                return next == WitnessProfileStatus.active
            case .active:
                return next == WitnessProfileStatus.suspended || next == WitnessProfileStatus.closed
            case .suspended:
                return next == WitnessProfileStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WitnessProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("witness profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netTotal() -> Double {
            return ((Double(createdAt) - Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> WitnessProfile {
            return WitnessProfile(
                code: code,
                label: label,
                windowDays: windowDays,
                phone: phone,
                createdAt: createdAt,
                segment: segment,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a witness profile in status draft.
    static func newWitnessProfile(_ code: String, label: String) -> WitnessProfile {
        return WitnessProfile(
            code: code,
            label: label,
            windowDays: 0,
            phone: "",
            createdAt: 0,
            segment: "",
            timezone: "",
            status: WitnessProfileStatus.draft
        )
    }
}
