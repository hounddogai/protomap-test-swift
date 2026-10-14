import AcmePlatform
import Foundation

extension Labs {
    /// Where a courier preference is in its life cycle.
    enum CourierPreferenceStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a courier preference and its current status.
    final class CourierPreference {
        var code: String
        var title: String
        var discount: Double
        var phone: String
        var country: String
        var timezone: String
        var cost: Double
        var visible: Bool
        var segment: String
        var priority: Int
        var status: CourierPreferenceStatus

        init(code: String, title: String, discount: Double, phone: String, country: String, timezone: String, cost: Double, visible: Bool, segment: String, priority: Int, status: CourierPreferenceStatus) {
            self.code = code
            self.title = title
            self.discount = discount
            self.phone = phone
            self.country = country
            self.timezone = timezone
            self.cost = cost
            self.visible = visible
            self.segment = segment
            self.priority = priority
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CourierPreferenceStatus) -> Bool {
            switch status {
            case .idle:
                return next == CourierPreferenceStatus.warming || next == CourierPreferenceStatus.ready
            case .warming:
                return next == CourierPreferenceStatus.draining
            case .ready:
                return next == CourierPreferenceStatus.draining || next == CourierPreferenceStatus.stopped
            case .draining:
                return next == CourierPreferenceStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CourierPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("courier preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func effectiveVolume() -> Double {
            return ((cost - Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> CourierPreference {
            return CourierPreference(
                code: code,
                title: title,
                discount: discount,
                phone: phone,
                country: country,
                timezone: timezone,
                cost: cost,
                visible: visible,
                segment: segment,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a courier preference in status idle.
    static func newCourierPreference(_ code: String, title: String) -> CourierPreference {
        return CourierPreference(
            code: code,
            title: title,
            discount: 0.0,
            phone: "",
            country: "",
            timezone: "",
            cost: 0.0,
            visible: false,
            segment: "",
            priority: 0,
            status: CourierPreferenceStatus.idle
        )
    }
}
