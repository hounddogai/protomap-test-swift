import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a manual risk score group is in its life cycle.
    enum ManualRiskScoreGroupStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One manual risk score group, with what the planners need to act on it.
    final class ManualRiskScoreGroup {
        var code: String
        var label: String
        var visible: Bool
        var description: String
        var checksum: String
        var refills: Int
        var phone: String
        var status: ManualRiskScoreGroupStatus

        init(code: String, label: String, visible: Bool, description: String, checksum: String, refills: Int, phone: String, status: ManualRiskScoreGroupStatus) {
            self.code = code
            self.label = label
            self.visible = visible
            self.description = description
            self.checksum = checksum
            self.refills = refills
            self.phone = phone
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

        func canMoveTo(_ next: ManualRiskScoreGroupStatus) -> Bool {
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
                return next == ManualRiskScoreGroupStatus.rejected
            case .rejected:
                return next == ManualRiskScoreGroupStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualRiskScoreGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual risk score group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func measuredValue() -> Double {
            return Double(refills)
        }

        func copyValue() -> ManualRiskScoreGroup {
            return ManualRiskScoreGroup(
                code: code,
                label: label,
                visible: visible,
                description: description,
                checksum: checksum,
                refills: refills,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a manual risk score group in status proposed.
    static func newManualRiskScoreGroup(_ code: String, label: String) -> ManualRiskScoreGroup {
        return ManualRiskScoreGroup(
            code: code,
            label: label,
            visible: false,
            description: "",
            checksum: "",
            refills: 0,
            phone: "",
            status: ManualRiskScoreGroupStatus.proposed
        )
    }
}
