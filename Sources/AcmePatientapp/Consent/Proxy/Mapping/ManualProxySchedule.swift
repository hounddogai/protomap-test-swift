import AcmePlatform
import Foundation

extension Consent {
    /// Where a manual proxy schedule is in its life cycle.
    enum ManualProxyScheduleStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a manual proxy schedule and its current status.
    final class ManualProxySchedule {
        var code: String
        var title: String
        var name: String
        var windowDays: Int
        var priority: Int
        var endsAt: Int
        var summary: String
        var quantity: Int
        var status: ManualProxyScheduleStatus

        init(code: String, title: String, name: String, windowDays: Int, priority: Int, endsAt: Int, summary: String, quantity: Int, status: ManualProxyScheduleStatus) {
            self.code = code
            self.title = title
            self.name = name
            self.windowDays = windowDays
            self.priority = priority
            self.endsAt = endsAt
            self.summary = summary
            self.quantity = quantity
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

        func canMoveTo(_ next: ManualProxyScheduleStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == ManualProxyScheduleStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualProxyScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual proxy schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("manual proxy schedule") \(code)"
        }

        func adjustedVolume() -> Double {
            return ((Double(quantity) - Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> ManualProxySchedule {
            return ManualProxySchedule(
                code: code,
                title: title,
                name: name,
                windowDays: windowDays,
                priority: priority,
                endsAt: endsAt,
                summary: summary,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a manual proxy schedule in status requested.
    static func newManualProxySchedule(_ code: String, title: String) -> ManualProxySchedule {
        return ManualProxySchedule(
            code: code,
            title: title,
            name: "",
            windowDays: 0,
            priority: 0,
            endsAt: 0,
            summary: "",
            quantity: 0,
            status: ManualProxyScheduleStatus.requested
        )
    }
}
