import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a manual substitution digest is in its life cycle.
    enum ManualSubstitutionDigestStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a manual substitution digest and its current status.
    final class ManualSubstitutionDigest {
        var code: String
        var name: String
        var visible: Bool
        var encounterID: String
        var notes: String
        var locale: String
        var copay: Double
        var amount: Double
        var status: ManualSubstitutionDigestStatus

        init(code: String, name: String, visible: Bool, encounterID: String, notes: String, locale: String, copay: Double, amount: Double, status: ManualSubstitutionDigestStatus) {
            self.code = code
            self.name = name
            self.visible = visible
            self.encounterID = encounterID
            self.notes = notes
            self.locale = locale
            self.copay = copay
            self.amount = amount
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

        func canMoveTo(_ next: ManualSubstitutionDigestStatus) -> Bool {
            switch status {
            case .proposed:
                return next == ManualSubstitutionDigestStatus.rejected
            case .approved:
                return next == ManualSubstitutionDigestStatus.rejected || next == ManualSubstitutionDigestStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: ManualSubstitutionDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual substitution digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func projectedTotal() -> Double {
            return ((amount - copay) * 100).rounded() / 100
        }

        func copyValue() -> ManualSubstitutionDigest {
            return ManualSubstitutionDigest(
                code: code,
                name: name,
                visible: visible,
                encounterID: encounterID,
                notes: notes,
                locale: locale,
                copay: copay,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a manual substitution digest in status proposed.
    static func newManualSubstitutionDigest(_ code: String, name: String) -> ManualSubstitutionDigest {
        return ManualSubstitutionDigest(
            code: code,
            name: name,
            visible: false,
            encounterID: "",
            notes: "",
            locale: "",
            copay: 0.0,
            amount: 0.0,
            status: ManualSubstitutionDigestStatus.proposed
        )
    }
}
