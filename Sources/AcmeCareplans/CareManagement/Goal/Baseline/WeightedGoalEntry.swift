import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a weighted goal entry is in its life cycle.
    enum WeightedGoalEntryStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A weighted goal entry. Its code is unique within a tenant.
    final class WeightedGoalEntry {
        var code: String
        var name: String
        var version: Int
        var ownerID: String
        var limit: Int
        var updatedAt: Int
        var retries: Int
        var ward: String
        var status: WeightedGoalEntryStatus

        init(code: String, name: String, version: Int, ownerID: String, limit: Int, updatedAt: Int, retries: Int, ward: String, status: WeightedGoalEntryStatus) {
            self.code = code
            self.name = name
            self.version = version
            self.ownerID = ownerID
            self.limit = limit
            self.updatedAt = updatedAt
            self.retries = retries
            self.ward = ward
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

        func canMoveTo(_ next: WeightedGoalEntryStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended:
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

        func moveTo(_ next: WeightedGoalEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted goal entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\("weighted goal entry") \(code)"
        }

        func adjustedValue() -> Double {
            return ((Double(version) + Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> WeightedGoalEntry {
            return WeightedGoalEntry(
                code: code,
                name: name,
                version: version,
                ownerID: ownerID,
                limit: limit,
                updatedAt: updatedAt,
                retries: retries,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a weighted goal entry in status draft.
    static func newWeightedGoalEntry(_ code: String, name: String) -> WeightedGoalEntry {
        return WeightedGoalEntry(
            code: code,
            name: name,
            version: 0,
            ownerID: "",
            limit: 0,
            updatedAt: 0,
            retries: 0,
            ward: "",
            status: WeightedGoalEntryStatus.draft
        )
    }
}
