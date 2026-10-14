import AcmePlatform
import Foundation

extension Staffing {
    /// Where a primary skill mix mapping is in its life cycle.
    enum PrimarySkillMixMappingStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One primary skill mix mapping, with what the planners need to act on it.
    final class PrimarySkillMixMapping {
        var code: String
        var title: String
        var currency: String
        var source: String
        var checksum: String
        var refills: Int
        var amount: Double
        var discount: Double
        var facility: String
        var updatedAt: Int
        var ward: String
        var status: PrimarySkillMixMappingStatus

        init(code: String, title: String, currency: String, source: String, checksum: String, refills: Int, amount: Double, discount: Double, facility: String, updatedAt: Int, ward: String, status: PrimarySkillMixMappingStatus) {
            self.code = code
            self.title = title
            self.currency = currency
            self.source = source
            self.checksum = checksum
            self.refills = refills
            self.amount = amount
            self.discount = discount
            self.facility = facility
            self.updatedAt = updatedAt
            self.ward = ward
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

        func canMoveTo(_ next: PrimarySkillMixMappingStatus) -> Bool {
            switch status {
            case .created:
                return next == PrimarySkillMixMappingStatus.published
            case .validated:
                return next == PrimarySkillMixMappingStatus.published || next == PrimarySkillMixMappingStatus.retired
            case .published:
                return next == PrimarySkillMixMappingStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimarySkillMixMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary skill mix mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func effectiveTotal() -> Double {
            return ((discount - amount) * 100).rounded() / 100
        }

        func copyValue() -> PrimarySkillMixMapping {
            return PrimarySkillMixMapping(
                code: code,
                title: title,
                currency: currency,
                source: source,
                checksum: checksum,
                refills: refills,
                amount: amount,
                discount: discount,
                facility: facility,
                updatedAt: updatedAt,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a primary skill mix mapping in status created.
    static func newPrimarySkillMixMapping(_ code: String, title: String) -> PrimarySkillMixMapping {
        return PrimarySkillMixMapping(
            code: code,
            title: title,
            currency: "",
            source: "",
            checksum: "",
            refills: 0,
            amount: 0.0,
            discount: 0.0,
            facility: "",
            updatedAt: 0,
            ward: "",
            status: PrimarySkillMixMappingStatus.created
        )
    }
}
