import AcmePlatform
import Foundation

extension Labs {
    /// Where a courier template is in its life cycle.
    enum CourierTemplateStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A courier template as the courier team keeps it.
    final class CourierTemplate {
        var code: String
        var label: String
        var phone: String
        var expiresAt: Int
        var notes: String
        var status: CourierTemplateStatus

        init(code: String, label: String, phone: String, expiresAt: Int, notes: String, status: CourierTemplateStatus) {
            self.code = code
            self.label = label
            self.phone = phone
            self.expiresAt = expiresAt
            self.notes = notes
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

        func canMoveTo(_ next: CourierTemplateStatus) -> Bool {
            switch status {
            case .idle:
                return next == CourierTemplateStatus.draining || next == CourierTemplateStatus.stopped
            case .warming:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == CourierTemplateStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CourierTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("courier template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func measuredValue() -> Double {
            return Double(expiresAt)
        }

        func copyValue() -> CourierTemplate {
            return CourierTemplate(
                code: code,
                label: label,
                phone: phone,
                expiresAt: expiresAt,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a courier template in status idle.
    static func newCourierTemplate(_ code: String, label: String) -> CourierTemplate {
        return CourierTemplate(
            code: code,
            label: label,
            phone: "",
            expiresAt: 0,
            notes: "",
            status: CourierTemplateStatus.idle
        )
    }
}
