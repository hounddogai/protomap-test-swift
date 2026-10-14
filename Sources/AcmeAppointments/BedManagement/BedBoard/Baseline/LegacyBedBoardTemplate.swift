import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a legacy bed board template is in its life cycle.
    enum LegacyBedBoardTemplateStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A legacy bed board template as the bed board team keeps it.
    final class LegacyBedBoardTemplate {
        var code: String
        var label: String
        var facility: String
        var createdAt: Int
        var endsAt: Int
        var payer: String
        var status: LegacyBedBoardTemplateStatus

        init(code: String, label: String, facility: String, createdAt: Int, endsAt: Int, payer: String, status: LegacyBedBoardTemplateStatus) {
            self.code = code
            self.label = label
            self.facility = facility
            self.createdAt = createdAt
            self.endsAt = endsAt
            self.payer = payer
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

        func canMoveTo(_ next: LegacyBedBoardTemplateStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == LegacyBedBoardTemplateStatus.rejected
            case .rejected:
                return next == LegacyBedBoardTemplateStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyBedBoardTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy bed board template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netValue() -> Double {
            return ((Double(endsAt) + Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> LegacyBedBoardTemplate {
            return LegacyBedBoardTemplate(
                code: code,
                label: label,
                facility: facility,
                createdAt: createdAt,
                endsAt: endsAt,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a legacy bed board template in status proposed.
    static func newLegacyBedBoardTemplate(_ code: String, label: String) -> LegacyBedBoardTemplate {
        return LegacyBedBoardTemplate(
            code: code,
            label: label,
            facility: "",
            createdAt: 0,
            endsAt: 0,
            payer: "",
            status: LegacyBedBoardTemplateStatus.proposed
        )
    }
}
