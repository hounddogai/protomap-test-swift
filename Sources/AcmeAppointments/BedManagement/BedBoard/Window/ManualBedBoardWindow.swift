import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a manual bed board window is in its life cycle.
    enum ManualBedBoardWindowStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a manual bed board window and its current status.
    final class ManualBedBoardWindow {
        var code: String
        var label: String
        var version: Int
        var margin: Double
        var phone: String
        var active: Bool
        var contactEmail: String
        var timezone: String
        var status: ManualBedBoardWindowStatus

        init(code: String, label: String, version: Int, margin: Double, phone: String, active: Bool, contactEmail: String, timezone: String, status: ManualBedBoardWindowStatus) {
            self.code = code
            self.label = label
            self.version = version
            self.margin = margin
            self.phone = phone
            self.active = active
            self.contactEmail = contactEmail
            self.timezone = timezone
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ManualBedBoardWindowStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == ManualBedBoardWindowStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualBedBoardWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual bed board window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func adjustedTotal() -> Double {
            return (Double(version) * margin * 100).rounded() / 100
        }

        func copyValue() -> ManualBedBoardWindow {
            return ManualBedBoardWindow(
                code: code,
                label: label,
                version: version,
                margin: margin,
                phone: phone,
                active: active,
                contactEmail: contactEmail,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a manual bed board window in status proposed.
    static func newManualBedBoardWindow(_ code: String, label: String) -> ManualBedBoardWindow {
        return ManualBedBoardWindow(
            code: code,
            label: label,
            version: 0,
            margin: 0.0,
            phone: "",
            active: false,
            contactEmail: "",
            timezone: "",
            status: ManualBedBoardWindowStatus.proposed
        )
    }
}
