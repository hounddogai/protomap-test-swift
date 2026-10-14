import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a denial ledger is in its life cycle.
    enum DenialLedgerStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A denial ledger. Its code is unique within a tenant.
    final class DenialLedger {
        var code: String
        var name: String
        var version: Int
        var ward: String
        var budget: Double
        var region: String
        var ratio: Double
        var allergy: String
        var priority: Int
        var archived: Bool
        var approved: Bool
        var status: DenialLedgerStatus

        init(code: String, name: String, version: Int, ward: String, budget: Double, region: String, ratio: Double, allergy: String, priority: Int, archived: Bool, approved: Bool, status: DenialLedgerStatus) {
            self.code = code
            self.name = name
            self.version = version
            self.ward = ward
            self.budget = budget
            self.region = region
            self.ratio = ratio
            self.allergy = allergy
            self.priority = priority
            self.archived = archived
            self.approved = approved
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

        func canMoveTo(_ next: DenialLedgerStatus) -> Bool {
            switch status {
            case .created:
                return next == DenialLedgerStatus.retired
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: DenialLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("denial ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func netVolume() -> Double {
            return ((Double(priority) - Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> DenialLedger {
            return DenialLedger(
                code: code,
                name: name,
                version: version,
                ward: ward,
                budget: budget,
                region: region,
                ratio: ratio,
                allergy: allergy,
                priority: priority,
                archived: archived,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a denial ledger in status created.
    static func newDenialLedger(_ code: String, name: String) -> DenialLedger {
        return DenialLedger(
            code: code,
            name: name,
            version: 0,
            ward: "",
            budget: 0.0,
            region: "",
            ratio: 0.0,
            allergy: "",
            priority: 0,
            archived: false,
            approved: false,
            status: DenialLedgerStatus.created
        )
    }
}
