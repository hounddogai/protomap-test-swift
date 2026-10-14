import AcmePlatform
import Foundation

extension Staffing {
    /// Where a capped credential ledger is in its life cycle.
    enum CappedCredentialLedgerStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A capped credential ledger. Its code is unique within a tenant.
    final class CappedCredentialLedger {
        var code: String
        var name: String
        var rate: Double
        var clinicianID: String
        var contactEmail: String
        var revision: Int
        var priority: Int
        var floorValue: Double
        var title: String
        var status: CappedCredentialLedgerStatus

        init(code: String, name: String, rate: Double, clinicianID: String, contactEmail: String, revision: Int, priority: Int, floorValue: Double, title: String, status: CappedCredentialLedgerStatus) {
            self.code = code
            self.name = name
            self.rate = rate
            self.clinicianID = clinicianID
            self.contactEmail = contactEmail
            self.revision = revision
            self.priority = priority
            self.floorValue = floorValue
            self.title = title
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CappedCredentialLedgerStatus) -> Bool {
            switch status {
            case .created:
                return next == CappedCredentialLedgerStatus.published || next == CappedCredentialLedgerStatus.retired
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == CappedCredentialLedgerStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedCredentialLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped credential ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func projectedValue() -> Double {
            return ((Double(priority) + rate) * 100).rounded() / 100
        }

        func copyValue() -> CappedCredentialLedger {
            return CappedCredentialLedger(
                code: code,
                name: name,
                rate: rate,
                clinicianID: clinicianID,
                contactEmail: contactEmail,
                revision: revision,
                priority: priority,
                floorValue: floorValue,
                title: title,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a capped credential ledger in status created.
    static func newCappedCredentialLedger(_ code: String, name: String) -> CappedCredentialLedger {
        return CappedCredentialLedger(
            code: code,
            name: name,
            rate: 0.0,
            clinicianID: "",
            contactEmail: "",
            revision: 0,
            priority: 0,
            floorValue: 0.0,
            title: "",
            status: CappedCredentialLedgerStatus.created
        )
    }
}
