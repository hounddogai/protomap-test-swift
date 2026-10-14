import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a manual transfer group is in its life cycle.
    enum ManualTransferGroupStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One manual transfer group, with what the planners need to act on it.
    final class ManualTransferGroup {
        var code: String
        var label: String
        var windowDays: Int
        var copay: Double
        var unit: String
        var attributes: [String: String]
        var visible: Bool
        var clinicianID: String
        var status: ManualTransferGroupStatus

        init(code: String, label: String, windowDays: Int, copay: Double, unit: String, attributes: [String: String], visible: Bool, clinicianID: String, status: ManualTransferGroupStatus) {
            self.code = code
            self.label = label
            self.windowDays = windowDays
            self.copay = copay
            self.unit = unit
            self.attributes = attributes
            self.visible = visible
            self.clinicianID = clinicianID
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

        func canMoveTo(_ next: ManualTransferGroupStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == ManualTransferGroupStatus.rejected || next == ManualTransferGroupStatus.withdrawn
            case .rejected:
                return next == ManualTransferGroupStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualTransferGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual transfer group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("manual transfer group") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func projectedTotal() -> Double {
            return ((Double(windowDays) - copay) * 100).rounded() / 100
        }

        func copyValue() -> ManualTransferGroup {
            return ManualTransferGroup(
                code: code,
                label: label,
                windowDays: windowDays,
                copay: copay,
                unit: unit,
                attributes: attributes,
                visible: visible,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a manual transfer group in status proposed.
    static func newManualTransferGroup(_ code: String, label: String) -> ManualTransferGroup {
        return ManualTransferGroup(
            code: code,
            label: label,
            windowDays: 0,
            copay: 0.0,
            unit: "",
            attributes: [:],
            visible: false,
            clinicianID: "",
            status: ManualTransferGroupStatus.proposed
        )
    }
}
