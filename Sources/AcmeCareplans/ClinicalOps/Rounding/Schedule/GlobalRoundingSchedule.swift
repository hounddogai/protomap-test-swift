import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a global rounding schedule is in its life cycle.
    enum GlobalRoundingScheduleStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a global rounding schedule and its current status.
    final class GlobalRoundingSchedule {
        var code: String
        var label: String
        var phone: String
        var title: String
        var ratio: Double
        var windowDays: Int
        var retries: Int
        var dosageMg: Double
        var description: String
        var payer: String
        var startsAt: Int
        var status: GlobalRoundingScheduleStatus

        init(code: String, label: String, phone: String, title: String, ratio: Double, windowDays: Int, retries: Int, dosageMg: Double, description: String, payer: String, startsAt: Int, status: GlobalRoundingScheduleStatus) {
            self.code = code
            self.label = label
            self.phone = phone
            self.title = title
            self.ratio = ratio
            self.windowDays = windowDays
            self.retries = retries
            self.dosageMg = dosageMg
            self.description = description
            self.payer = payer
            self.startsAt = startsAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GlobalRoundingScheduleStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == GlobalRoundingScheduleStatus.revoked || next == GlobalRoundingScheduleStatus.expired
            case .revoked:
                return next == GlobalRoundingScheduleStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalRoundingScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global rounding schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("global rounding schedule") \(code)"
        }

        func adjustedTotal() -> Double {
            return ((ratio - Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalRoundingSchedule {
            return GlobalRoundingSchedule(
                code: code,
                label: label,
                phone: phone,
                title: title,
                ratio: ratio,
                windowDays: windowDays,
                retries: retries,
                dosageMg: dosageMg,
                description: description,
                payer: payer,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a global rounding schedule in status requested.
    static func newGlobalRoundingSchedule(_ code: String, label: String) -> GlobalRoundingSchedule {
        return GlobalRoundingSchedule(
            code: code,
            label: label,
            phone: "",
            title: "",
            ratio: 0.0,
            windowDays: 0,
            retries: 0,
            dosageMg: 0.0,
            description: "",
            payer: "",
            startsAt: 0,
            status: GlobalRoundingScheduleStatus.requested
        )
    }
}
