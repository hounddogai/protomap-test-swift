import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a manual remittance record is in its life cycle.
    enum ManualRemittanceRecordStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a manual remittance record and its current status.
    final class ManualRemittanceRecord {
        var code: String
        var name: String
        var batchSize: Int
        var graceDays: Int
        var summary: String
        var procedureCode: String
        var description: String
        var status: ManualRemittanceRecordStatus

        init(code: String, name: String, batchSize: Int, graceDays: Int, summary: String, procedureCode: String, description: String, status: ManualRemittanceRecordStatus) {
            self.code = code
            self.name = name
            self.batchSize = batchSize
            self.graceDays = graceDays
            self.summary = summary
            self.procedureCode = procedureCode
            self.description = description
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

        func canMoveTo(_ next: ManualRemittanceRecordStatus) -> Bool {
            switch status {
            case .draft:
                return next == ManualRemittanceRecordStatus.pending || next == ManualRemittanceRecordStatus.closed
            case .pending:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: ManualRemittanceRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual remittance record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func adjustedTotal() -> Double {
            return (Double(batchSize) * Double(graceDays) * 100).rounded() / 100
        }

        func copyValue() -> ManualRemittanceRecord {
            return ManualRemittanceRecord(
                code: code,
                name: name,
                batchSize: batchSize,
                graceDays: graceDays,
                summary: summary,
                procedureCode: procedureCode,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a manual remittance record in status draft.
    static func newManualRemittanceRecord(_ code: String, name: String) -> ManualRemittanceRecord {
        return ManualRemittanceRecord(
            code: code,
            name: name,
            batchSize: 0,
            graceDays: 0,
            summary: "",
            procedureCode: "",
            description: "",
            status: ManualRemittanceRecordStatus.draft
        )
    }
}
