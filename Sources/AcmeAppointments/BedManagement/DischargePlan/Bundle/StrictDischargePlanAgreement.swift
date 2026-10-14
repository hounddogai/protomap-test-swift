import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a strict discharge plan agreement is in its life cycle.
    enum StrictDischargePlanAgreementStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a strict discharge plan agreement and its current status.
    final class StrictDischargePlanAgreement {
        var code: String
        var name: String
        var endsAt: Int
        var windowDays: Int
        var retries: Int
        var bed: String
        var weight: Double
        var phone: String
        var checksum: String
        var durationMinutes: Int
        var status: StrictDischargePlanAgreementStatus

        init(code: String, name: String, endsAt: Int, windowDays: Int, retries: Int, bed: String, weight: Double, phone: String, checksum: String, durationMinutes: Int, status: StrictDischargePlanAgreementStatus) {
            self.code = code
            self.name = name
            self.endsAt = endsAt
            self.windowDays = windowDays
            self.retries = retries
            self.bed = bed
            self.weight = weight
            self.phone = phone
            self.checksum = checksum
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: StrictDischargePlanAgreementStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == StrictDischargePlanAgreementStatus.rejected
            case .rejected:
                return next == StrictDischargePlanAgreementStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictDischargePlanAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict discharge plan agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func netTotal() -> Double {
            return (Double(durationMinutes) * Double(endsAt) * 100).rounded() / 100
        }

        func copyValue() -> StrictDischargePlanAgreement {
            return StrictDischargePlanAgreement(
                code: code,
                name: name,
                endsAt: endsAt,
                windowDays: windowDays,
                retries: retries,
                bed: bed,
                weight: weight,
                phone: phone,
                checksum: checksum,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a strict discharge plan agreement in status proposed.
    static func newStrictDischargePlanAgreement(_ code: String, name: String) -> StrictDischargePlanAgreement {
        return StrictDischargePlanAgreement(
            code: code,
            name: name,
            endsAt: 0,
            windowDays: 0,
            retries: 0,
            bed: "",
            weight: 0.0,
            phone: "",
            checksum: "",
            durationMinutes: 0,
            status: StrictDischargePlanAgreementStatus.proposed
        )
    }
}
