import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a regional formulary cycle is in its life cycle.
    enum RegionalFormularyCycleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A regional formulary cycle as the formulary team keeps it.
    final class RegionalFormularyCycle {
        var code: String
        var name: String
        var contactEmail: String
        var batchSize: Int
        var encounterID: String
        var bed: String
        var status: RegionalFormularyCycleStatus

        init(code: String, name: String, contactEmail: String, batchSize: Int, encounterID: String, bed: String, status: RegionalFormularyCycleStatus) {
            self.code = code
            self.name = name
            self.contactEmail = contactEmail
            self.batchSize = batchSize
            self.encounterID = encounterID
            self.bed = bed
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

        func canMoveTo(_ next: RegionalFormularyCycleStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == RegionalFormularyCycleStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalFormularyCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional formulary cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("regional formulary cycle") \(code)"
        }

        func measuredValue() -> Double {
            return Double(batchSize)
        }

        func copyValue() -> RegionalFormularyCycle {
            return RegionalFormularyCycle(
                code: code,
                name: name,
                contactEmail: contactEmail,
                batchSize: batchSize,
                encounterID: encounterID,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a regional formulary cycle in status proposed.
    static func newRegionalFormularyCycle(_ code: String, name: String) -> RegionalFormularyCycle {
        return RegionalFormularyCycle(
            code: code,
            name: name,
            contactEmail: "",
            batchSize: 0,
            encounterID: "",
            bed: "",
            status: RegionalFormularyCycleStatus.proposed
        )
    }
}
