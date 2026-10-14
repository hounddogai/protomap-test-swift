import AcmePlatform
import Foundation

extension Labs {
    /// Where a courier ledger is in its life cycle.
    enum CourierLedgerStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A courier ledger as the courier team keeps it.
    final class CourierLedger {
        var code: String
        var title: String
        var procedureCode: String
        var durationMinutes: Int
        var tags: [String]
        var threshold: Double
        var margin: Double
        var discount: Double
        var checksum: String
        var channel: String
        var diagnosisCode: String
        var status: CourierLedgerStatus

        init(code: String, title: String, procedureCode: String, durationMinutes: Int, tags: [String], threshold: Double, margin: Double, discount: Double, checksum: String, channel: String, diagnosisCode: String, status: CourierLedgerStatus) {
            self.code = code
            self.title = title
            self.procedureCode = procedureCode
            self.durationMinutes = durationMinutes
            self.tags = tags
            self.threshold = threshold
            self.margin = margin
            self.discount = discount
            self.checksum = checksum
            self.channel = channel
            self.diagnosisCode = diagnosisCode
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

        func canMoveTo(_ next: CourierLedgerStatus) -> Bool {
            switch status {
            case .proposed:
                return next == CourierLedgerStatus.rejected
            case .approved:
                return next == CourierLedgerStatus.rejected || next == CourierLedgerStatus.withdrawn
            case .rejected:
                return next == CourierLedgerStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CourierLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("courier ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedExposure() -> Double {
            return ((margin - Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> CourierLedger {
            return CourierLedger(
                code: code,
                title: title,
                procedureCode: procedureCode,
                durationMinutes: durationMinutes,
                tags: tags,
                threshold: threshold,
                margin: margin,
                discount: discount,
                checksum: checksum,
                channel: channel,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a courier ledger in status proposed.
    static func newCourierLedger(_ code: String, title: String) -> CourierLedger {
        return CourierLedger(
            code: code,
            title: title,
            procedureCode: "",
            durationMinutes: 0,
            tags: [],
            threshold: 0.0,
            margin: 0.0,
            discount: 0.0,
            checksum: "",
            channel: "",
            diagnosisCode: "",
            status: CourierLedgerStatus.proposed
        )
    }
}
