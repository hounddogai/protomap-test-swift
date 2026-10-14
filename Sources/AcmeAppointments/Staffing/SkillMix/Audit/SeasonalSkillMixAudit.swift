import AcmePlatform
import Foundation

extension Staffing {
    /// Where a seasonal skill mix audit is in its life cycle.
    enum SeasonalSkillMixAuditStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A seasonal skill mix audit. Its code is unique within a tenant.
    final class SeasonalSkillMixAudit {
        var code: String
        var title: String
        var dosageMg: Double
        var ward: String
        var expiresAt: Int
        var facility: String
        var segment: String
        var status: SeasonalSkillMixAuditStatus

        init(code: String, title: String, dosageMg: Double, ward: String, expiresAt: Int, facility: String, segment: String, status: SeasonalSkillMixAuditStatus) {
            self.code = code
            self.title = title
            self.dosageMg = dosageMg
            self.ward = ward
            self.expiresAt = expiresAt
            self.facility = facility
            self.segment = segment
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

        func canMoveTo(_ next: SeasonalSkillMixAuditStatus) -> Bool {
            switch status {
            case .created:
                return next == SeasonalSkillMixAuditStatus.validated || next == SeasonalSkillMixAuditStatus.retired
            case .validated:
                return next == SeasonalSkillMixAuditStatus.retired
            case .published:
                return next == SeasonalSkillMixAuditStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalSkillMixAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal skill mix audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func adjustedLoad() -> Double {
            return ((Double(expiresAt) + dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalSkillMixAudit {
            return SeasonalSkillMixAudit(
                code: code,
                title: title,
                dosageMg: dosageMg,
                ward: ward,
                expiresAt: expiresAt,
                facility: facility,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a seasonal skill mix audit in status created.
    static func newSeasonalSkillMixAudit(_ code: String, title: String) -> SeasonalSkillMixAudit {
        return SeasonalSkillMixAudit(
            code: code,
            title: title,
            dosageMg: 0.0,
            ward: "",
            expiresAt: 0,
            facility: "",
            segment: "",
            status: SeasonalSkillMixAuditStatus.created
        )
    }
}
