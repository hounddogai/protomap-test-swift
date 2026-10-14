import AcmePlatform
import Foundation

extension Imaging {
    /// Where a care protocol schedule is in its life cycle.
    enum CareProtocolScheduleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A care protocol schedule. Its code is unique within a tenant.
    final class CareProtocolSchedule {
        var code: String
        var title: String
        var diagnosisCode: String
        var phone: String
        var threshold: Double
        var payer: String
        var approved: Bool
        var visible: Bool
        var startsAt: Int
        var locale: String
        var ceiling: Double
        var status: CareProtocolScheduleStatus

        init(code: String, title: String, diagnosisCode: String, phone: String, threshold: Double, payer: String, approved: Bool, visible: Bool, startsAt: Int, locale: String, ceiling: Double, status: CareProtocolScheduleStatus) {
            self.code = code
            self.title = title
            self.diagnosisCode = diagnosisCode
            self.phone = phone
            self.threshold = threshold
            self.payer = payer
            self.approved = approved
            self.visible = visible
            self.startsAt = startsAt
            self.locale = locale
            self.ceiling = ceiling
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CareProtocolScheduleStatus) -> Bool {
            switch status {
            case .new:
                return next == CareProtocolScheduleStatus.failed
            case .queued:
                return next == CareProtocolScheduleStatus.running || next == CareProtocolScheduleStatus.failed
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == CareProtocolScheduleStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareProtocolScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func weightedLoad() -> Double {
            return ((ceiling - threshold) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolSchedule {
            return CareProtocolSchedule(
                code: code,
                title: title,
                diagnosisCode: diagnosisCode,
                phone: phone,
                threshold: threshold,
                payer: payer,
                approved: approved,
                visible: visible,
                startsAt: startsAt,
                locale: locale,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a care protocol schedule in status new.
    static func newCareProtocolSchedule(_ code: String, title: String) -> CareProtocolSchedule {
        return CareProtocolSchedule(
            code: code,
            title: title,
            diagnosisCode: "",
            phone: "",
            threshold: 0.0,
            payer: "",
            approved: false,
            visible: false,
            startsAt: 0,
            locale: "",
            ceiling: 0.0,
            status: CareProtocolScheduleStatus.new
        )
    }
}
