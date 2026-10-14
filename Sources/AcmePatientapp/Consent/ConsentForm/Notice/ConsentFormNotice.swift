import AcmePlatform
import Foundation

extension Consent {
    /// Where a consent form notice is in its life cycle.
    enum ConsentFormNoticeStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One consent form notice, with what the planners need to act on it.
    final class ConsentFormNotice {
        var code: String
        var name: String
        var floorValue: Double
        var windowDays: Int
        var refills: Int
        var approved: Bool
        var status: ConsentFormNoticeStatus

        init(code: String, name: String, floorValue: Double, windowDays: Int, refills: Int, approved: Bool, status: ConsentFormNoticeStatus) {
            self.code = code
            self.name = name
            self.floorValue = floorValue
            self.windowDays = windowDays
            self.refills = refills
            self.approved = approved
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ConsentFormNoticeStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == ConsentFormNoticeStatus.cancelled
            case .completed:
                return next == ConsentFormNoticeStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ConsentFormNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("consent form notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("consent form notice") \(code)"
        }

        func projectedExposure() -> Double {
            return (floorValue * Double(refills) * 100).rounded() / 100
        }

        func copyValue() -> ConsentFormNotice {
            return ConsentFormNotice(
                code: code,
                name: name,
                floorValue: floorValue,
                windowDays: windowDays,
                refills: refills,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a consent form notice in status planned.
    static func newConsentFormNotice(_ code: String, name: String) -> ConsentFormNotice {
        return ConsentFormNotice(
            code: code,
            name: name,
            floorValue: 0.0,
            windowDays: 0,
            refills: 0,
            approved: false,
            status: ConsentFormNoticeStatus.planned
        )
    }
}
