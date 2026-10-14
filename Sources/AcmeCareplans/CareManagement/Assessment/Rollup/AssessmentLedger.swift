import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a assessment ledger is in its life cycle.
    enum AssessmentLedgerStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A assessment ledger as the assessment team keeps it.
    final class AssessmentLedger {
        var code: String
        var name: String
        var version: Int
        var contactEmail: String
        var weight: Double
        var capacity: Int
        var unit: String
        var status: AssessmentLedgerStatus

        init(code: String, name: String, version: Int, contactEmail: String, weight: Double, capacity: Int, unit: String, status: AssessmentLedgerStatus) {
            self.code = code
            self.name = name
            self.version = version
            self.contactEmail = contactEmail
            self.weight = weight
            self.capacity = capacity
            self.unit = unit
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

        func canMoveTo(_ next: AssessmentLedgerStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == AssessmentLedgerStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: AssessmentLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("assessment ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func projectedVolume() -> Double {
            return (Double(capacity) * weight * 100).rounded() / 100
        }

        func copyValue() -> AssessmentLedger {
            return AssessmentLedger(
                code: code,
                name: name,
                version: version,
                contactEmail: contactEmail,
                weight: weight,
                capacity: capacity,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a assessment ledger in status created.
    static func newAssessmentLedger(_ code: String, name: String) -> AssessmentLedger {
        return AssessmentLedger(
            code: code,
            name: name,
            version: 0,
            contactEmail: "",
            weight: 0.0,
            capacity: 0,
            unit: "",
            status: AssessmentLedgerStatus.created
        )
    }
}
