import AcmePlatform
import Foundation

extension Labs {
    /// Where a seasonal specimen ledger is in its life cycle.
    enum SeasonalSpecimenLedgerStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A seasonal specimen ledger as the specimen team keeps it.
    final class SeasonalSpecimenLedger {
        var code: String
        var label: String
        var allergy: String
        var createdAt: Int
        var category: String
        var checksum: String
        var status: SeasonalSpecimenLedgerStatus

        init(code: String, label: String, allergy: String, createdAt: Int, category: String, checksum: String, status: SeasonalSpecimenLedgerStatus) {
            self.code = code
            self.label = label
            self.allergy = allergy
            self.createdAt = createdAt
            self.category = category
            self.checksum = checksum
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

        func canMoveTo(_ next: SeasonalSpecimenLedgerStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == SeasonalSpecimenLedgerStatus.active || next == SeasonalSpecimenLedgerStatus.closed
            case .active:
                switch next {
                case .suspended, .closed:
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

        func moveTo(_ next: SeasonalSpecimenLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal specimen ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("seasonal specimen ledger") \(code)"
        }

        func measuredValue() -> Double {
            return Double(createdAt)
        }

        func copyValue() -> SeasonalSpecimenLedger {
            return SeasonalSpecimenLedger(
                code: code,
                label: label,
                allergy: allergy,
                createdAt: createdAt,
                category: category,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a seasonal specimen ledger in status draft.
    static func newSeasonalSpecimenLedger(_ code: String, label: String) -> SeasonalSpecimenLedger {
        return SeasonalSpecimenLedger(
            code: code,
            label: label,
            allergy: "",
            createdAt: 0,
            category: "",
            checksum: "",
            status: SeasonalSpecimenLedgerStatus.draft
        )
    }
}
