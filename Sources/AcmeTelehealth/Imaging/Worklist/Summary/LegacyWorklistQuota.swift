import AcmePlatform
import Foundation

extension Imaging {
    /// Where a legacy worklist quota is in its life cycle.
    enum LegacyWorklistQuotaStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A legacy worklist quota. Its code is unique within a tenant.
    final class LegacyWorklistQuota {
        var code: String
        var name: String
        var category: String
        var ceiling: Double
        var checksum: String
        var dosageMg: Double
        var version: Int
        var procedureCode: String
        var status: LegacyWorklistQuotaStatus

        init(code: String, name: String, category: String, ceiling: Double, checksum: String, dosageMg: Double, version: Int, procedureCode: String, status: LegacyWorklistQuotaStatus) {
            self.code = code
            self.name = name
            self.category = category
            self.ceiling = ceiling
            self.checksum = checksum
            self.dosageMg = dosageMg
            self.version = version
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: LegacyWorklistQuotaStatus) -> Bool {
            switch status {
            case .draft:
                return next == LegacyWorklistQuotaStatus.pending
            case .pending:
                return next == LegacyWorklistQuotaStatus.active || next == LegacyWorklistQuotaStatus.closed
            case .active:
                return next == LegacyWorklistQuotaStatus.suspended
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

        func moveTo(_ next: LegacyWorklistQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy worklist quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func effectiveVolume() -> Double {
            return ((dosageMg - ceiling) * 100).rounded() / 100
        }

        func copyValue() -> LegacyWorklistQuota {
            return LegacyWorklistQuota(
                code: code,
                name: name,
                category: category,
                ceiling: ceiling,
                checksum: checksum,
                dosageMg: dosageMg,
                version: version,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a legacy worklist quota in status draft.
    static func newLegacyWorklistQuota(_ code: String, name: String) -> LegacyWorklistQuota {
        return LegacyWorklistQuota(
            code: code,
            name: name,
            category: "",
            ceiling: 0.0,
            checksum: "",
            dosageMg: 0.0,
            version: 0,
            procedureCode: "",
            status: LegacyWorklistQuotaStatus.draft
        )
    }
}
