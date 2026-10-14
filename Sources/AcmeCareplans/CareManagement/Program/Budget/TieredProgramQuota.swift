import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a tiered program quota is in its life cycle.
    enum TieredProgramQuotaStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a tiered program quota and its current status.
    final class TieredProgramQuota {
        var code: String
        var name: String
        var batchSize: Int
        var expiresAt: Int
        var notes: String
        var endsAt: Int
        var durationMinutes: Int
        var createdAt: Int
        var refills: Int
        var description: String
        var status: TieredProgramQuotaStatus

        init(code: String, name: String, batchSize: Int, expiresAt: Int, notes: String, endsAt: Int, durationMinutes: Int, createdAt: Int, refills: Int, description: String, status: TieredProgramQuotaStatus) {
            self.code = code
            self.name = name
            self.batchSize = batchSize
            self.expiresAt = expiresAt
            self.notes = notes
            self.endsAt = endsAt
            self.durationMinutes = durationMinutes
            self.createdAt = createdAt
            self.refills = refills
            self.description = description
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

        func canMoveTo(_ next: TieredProgramQuotaStatus) -> Bool {
            switch status {
            case .proposed:
                return next == TieredProgramQuotaStatus.withdrawn
            case .approved:
                return next == TieredProgramQuotaStatus.rejected || next == TieredProgramQuotaStatus.withdrawn
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

        func moveTo(_ next: TieredProgramQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered program quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func weightedTotal() -> Double {
            return ((Double(batchSize) + Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> TieredProgramQuota {
            return TieredProgramQuota(
                code: code,
                name: name,
                batchSize: batchSize,
                expiresAt: expiresAt,
                notes: notes,
                endsAt: endsAt,
                durationMinutes: durationMinutes,
                createdAt: createdAt,
                refills: refills,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a tiered program quota in status proposed.
    static func newTieredProgramQuota(_ code: String, name: String) -> TieredProgramQuota {
        return TieredProgramQuota(
            code: code,
            name: name,
            batchSize: 0,
            expiresAt: 0,
            notes: "",
            endsAt: 0,
            durationMinutes: 0,
            createdAt: 0,
            refills: 0,
            description: "",
            status: TieredProgramQuotaStatus.proposed
        )
    }
}
