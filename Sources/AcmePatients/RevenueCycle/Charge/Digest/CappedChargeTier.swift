import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a capped charge tier is in its life cycle.
    enum CappedChargeTierStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a capped charge tier and its current status.
    final class CappedChargeTier {
        var code: String
        var name: String
        var diagnosisCode: String
        var graceDays: Int
        var unit: String
        var durationMinutes: Int
        var clinicianID: String
        var endsAt: Int
        var locale: String
        var approved: Bool
        var updatedAt: Int
        var status: CappedChargeTierStatus

        init(code: String, name: String, diagnosisCode: String, graceDays: Int, unit: String, durationMinutes: Int, clinicianID: String, endsAt: Int, locale: String, approved: Bool, updatedAt: Int, status: CappedChargeTierStatus) {
            self.code = code
            self.name = name
            self.diagnosisCode = diagnosisCode
            self.graceDays = graceDays
            self.unit = unit
            self.durationMinutes = durationMinutes
            self.clinicianID = clinicianID
            self.endsAt = endsAt
            self.locale = locale
            self.approved = approved
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: CappedChargeTierStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == CappedChargeTierStatus.rejected || next == CappedChargeTierStatus.withdrawn
            case .rejected:
                return next == CappedChargeTierStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedChargeTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped charge tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func netTotal() -> Double {
            return ((Double(durationMinutes) - Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> CappedChargeTier {
            return CappedChargeTier(
                code: code,
                name: name,
                diagnosisCode: diagnosisCode,
                graceDays: graceDays,
                unit: unit,
                durationMinutes: durationMinutes,
                clinicianID: clinicianID,
                endsAt: endsAt,
                locale: locale,
                approved: approved,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a capped charge tier in status proposed.
    static func newCappedChargeTier(_ code: String, name: String) -> CappedChargeTier {
        return CappedChargeTier(
            code: code,
            name: name,
            diagnosisCode: "",
            graceDays: 0,
            unit: "",
            durationMinutes: 0,
            clinicianID: "",
            endsAt: 0,
            locale: "",
            approved: false,
            updatedAt: 0,
            status: CappedChargeTierStatus.proposed
        )
    }
}
