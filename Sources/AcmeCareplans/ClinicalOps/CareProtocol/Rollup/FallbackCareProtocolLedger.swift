import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a fallback care protocol ledger is in its life cycle.
    enum FallbackCareProtocolLedgerStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A fallback care protocol ledger. Its code is unique within a tenant.
    final class FallbackCareProtocolLedger {
        var code: String
        var name: String
        var encounterID: String
        var copay: Double
        var diagnosisCode: String
        var priority: Int
        var phone: String
        var windowDays: Int
        var margin: Double
        var status: FallbackCareProtocolLedgerStatus

        init(code: String, name: String, encounterID: String, copay: Double, diagnosisCode: String, priority: Int, phone: String, windowDays: Int, margin: Double, status: FallbackCareProtocolLedgerStatus) {
            self.code = code
            self.name = name
            self.encounterID = encounterID
            self.copay = copay
            self.diagnosisCode = diagnosisCode
            self.priority = priority
            self.phone = phone
            self.windowDays = windowDays
            self.margin = margin
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

        func canMoveTo(_ next: FallbackCareProtocolLedgerStatus) -> Bool {
            switch status {
            case .draft:
                return next == FallbackCareProtocolLedgerStatus.suspended
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == FallbackCareProtocolLedgerStatus.suspended || next == FallbackCareProtocolLedgerStatus.closed
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

        func moveTo(_ next: FallbackCareProtocolLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback care protocol ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func adjustedValue() -> Double {
            return ((Double(windowDays) - margin) * 100).rounded() / 100
        }

        func copyValue() -> FallbackCareProtocolLedger {
            return FallbackCareProtocolLedger(
                code: code,
                name: name,
                encounterID: encounterID,
                copay: copay,
                diagnosisCode: diagnosisCode,
                priority: priority,
                phone: phone,
                windowDays: windowDays,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a fallback care protocol ledger in status draft.
    static func newFallbackCareProtocolLedger(_ code: String, name: String) -> FallbackCareProtocolLedger {
        return FallbackCareProtocolLedger(
            code: code,
            name: name,
            encounterID: "",
            copay: 0.0,
            diagnosisCode: "",
            priority: 0,
            phone: "",
            windowDays: 0,
            margin: 0.0,
            status: FallbackCareProtocolLedgerStatus.draft
        )
    }
}
