import AcmePlatform
import Foundation

extension Referrals {
    /// Where a tiered slot snapshot is in its life cycle.
    enum TieredSlotSnapshotStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One tiered slot snapshot, with what the planners need to act on it.
    final class TieredSlotSnapshot {
        var code: String
        var name: String
        var updatedAt: Int
        var attributes: [String: String]
        var timezone: String
        var acuity: Int
        var reviewer: String
        var cost: Double
        var country: String
        var discount: Double
        var status: TieredSlotSnapshotStatus

        init(code: String, name: String, updatedAt: Int, attributes: [String: String], timezone: String, acuity: Int, reviewer: String, cost: Double, country: String, discount: Double, status: TieredSlotSnapshotStatus) {
            self.code = code
            self.name = name
            self.updatedAt = updatedAt
            self.attributes = attributes
            self.timezone = timezone
            self.acuity = acuity
            self.reviewer = reviewer
            self.cost = cost
            self.country = country
            self.discount = discount
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

        func canMoveTo(_ next: TieredSlotSnapshotStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended:
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

        func moveTo(_ next: TieredSlotSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered slot snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("tiered slot snapshot") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func effectiveLoad() -> Double {
            return ((Double(updatedAt) - discount) * 100).rounded() / 100
        }

        func copyValue() -> TieredSlotSnapshot {
            return TieredSlotSnapshot(
                code: code,
                name: name,
                updatedAt: updatedAt,
                attributes: attributes,
                timezone: timezone,
                acuity: acuity,
                reviewer: reviewer,
                cost: cost,
                country: country,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a tiered slot snapshot in status draft.
    static func newTieredSlotSnapshot(_ code: String, name: String) -> TieredSlotSnapshot {
        return TieredSlotSnapshot(
            code: code,
            name: name,
            updatedAt: 0,
            attributes: [:],
            timezone: "",
            acuity: 0,
            reviewer: "",
            cost: 0.0,
            country: "",
            discount: 0.0,
            status: TieredSlotSnapshotStatus.draft
        )
    }
}
