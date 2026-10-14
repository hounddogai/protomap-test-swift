import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a program entry is in its life cycle.
    enum ProgramEntryStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A program entry as the program team keeps it.
    final class ProgramEntry {
        var code: String
        var label: String
        var quantity: Int
        var visible: Bool
        var copay: Double
        var sequence: Int
        var retries: Int
        var visitMinutes: Int
        var region: String
        var currency: String
        var summary: String
        var status: ProgramEntryStatus

        init(code: String, label: String, quantity: Int, visible: Bool, copay: Double, sequence: Int, retries: Int, visitMinutes: Int, region: String, currency: String, summary: String, status: ProgramEntryStatus) {
            self.code = code
            self.label = label
            self.quantity = quantity
            self.visible = visible
            self.copay = copay
            self.sequence = sequence
            self.retries = retries
            self.visitMinutes = visitMinutes
            self.region = region
            self.currency = currency
            self.summary = summary
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

        func canMoveTo(_ next: ProgramEntryStatus) -> Bool {
            switch status {
            case .requested:
                return next == ProgramEntryStatus.granted || next == ProgramEntryStatus.revoked
            case .granted:
                return next == ProgramEntryStatus.expired
            case .revoked:
                return next == ProgramEntryStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ProgramEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("program entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func projectedValue() -> Double {
            return (copay * Double(sequence) * 100).rounded() / 100
        }

        func copyValue() -> ProgramEntry {
            return ProgramEntry(
                code: code,
                label: label,
                quantity: quantity,
                visible: visible,
                copay: copay,
                sequence: sequence,
                retries: retries,
                visitMinutes: visitMinutes,
                region: region,
                currency: currency,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a program entry in status requested.
    static func newProgramEntry(_ code: String, label: String) -> ProgramEntry {
        return ProgramEntry(
            code: code,
            label: label,
            quantity: 0,
            visible: false,
            copay: 0.0,
            sequence: 0,
            retries: 0,
            visitMinutes: 0,
            region: "",
            currency: "",
            summary: "",
            status: ProgramEntryStatus.requested
        )
    }
}
