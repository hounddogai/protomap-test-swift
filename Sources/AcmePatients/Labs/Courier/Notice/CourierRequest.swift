import AcmePlatform
import Foundation

extension Labs {
    /// Where a courier request is in its life cycle.
    enum CourierRequestStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A courier request. Its code is unique within a tenant.
    final class CourierRequest {
        var code: String
        var title: String
        var maximum: Double
        var phone: String
        var visible: Bool
        var status: CourierRequestStatus

        init(code: String, title: String, maximum: Double, phone: String, visible: Bool, status: CourierRequestStatus) {
            self.code = code
            self.title = title
            self.maximum = maximum
            self.phone = phone
            self.visible = visible
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

        func canMoveTo(_ next: CourierRequestStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == CourierRequestStatus.done || next == CourierRequestStatus.failed
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: CourierRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("courier request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func measuredValue() -> Double {
            return maximum
        }

        func copyValue() -> CourierRequest {
            return CourierRequest(
                code: code,
                title: title,
                maximum: maximum,
                phone: phone,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a courier request in status new.
    static func newCourierRequest(_ code: String, title: String) -> CourierRequest {
        return CourierRequest(
            code: code,
            title: title,
            maximum: 0.0,
            phone: "",
            visible: false,
            status: CourierRequestStatus.new
        )
    }
}
