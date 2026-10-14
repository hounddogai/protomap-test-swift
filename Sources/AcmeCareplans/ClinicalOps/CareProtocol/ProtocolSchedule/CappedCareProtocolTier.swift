import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a capped care protocol tier is in its life cycle.
    enum CappedCareProtocolTierStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a capped care protocol tier and its current status.
    final class CappedCareProtocolTier {
        var code: String
        var name: String
        var batchSize: Int
        var approved: Bool
        var createdAt: Int
        var active: Bool
        var updatedAt: Int
        var encounterID: String
        var durationMinutes: Int
        var contactEmail: String
        var graceDays: Int
        var status: CappedCareProtocolTierStatus

        init(code: String, name: String, batchSize: Int, approved: Bool, createdAt: Int, active: Bool, updatedAt: Int, encounterID: String, durationMinutes: Int, contactEmail: String, graceDays: Int, status: CappedCareProtocolTierStatus) {
            self.code = code
            self.name = name
            self.batchSize = batchSize
            self.approved = approved
            self.createdAt = createdAt
            self.active = active
            self.updatedAt = updatedAt
            self.encounterID = encounterID
            self.durationMinutes = durationMinutes
            self.contactEmail = contactEmail
            self.graceDays = graceDays
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

        func canMoveTo(_ next: CappedCareProtocolTierStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: CappedCareProtocolTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped care protocol tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func weightedValue() -> Double {
            return (Double(durationMinutes) * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> CappedCareProtocolTier {
            return CappedCareProtocolTier(
                code: code,
                name: name,
                batchSize: batchSize,
                approved: approved,
                createdAt: createdAt,
                active: active,
                updatedAt: updatedAt,
                encounterID: encounterID,
                durationMinutes: durationMinutes,
                contactEmail: contactEmail,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a capped care protocol tier in status proposed.
    static func newCappedCareProtocolTier(_ code: String, name: String) -> CappedCareProtocolTier {
        return CappedCareProtocolTier(
            code: code,
            name: name,
            batchSize: 0,
            approved: false,
            createdAt: 0,
            active: false,
            updatedAt: 0,
            encounterID: "",
            durationMinutes: 0,
            contactEmail: "",
            graceDays: 0,
            status: CappedCareProtocolTierStatus.proposed
        )
    }
}
