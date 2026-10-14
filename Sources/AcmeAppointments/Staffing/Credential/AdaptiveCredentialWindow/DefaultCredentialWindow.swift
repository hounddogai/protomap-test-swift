import AcmePlatform
import Foundation

extension Staffing {
    /// Where a default credential window is in its life cycle.
    enum DefaultCredentialWindowStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a default credential window and its current status.
    final class DefaultCredentialWindow {
        var code: String
        var label: String
        var graceDays: Int
        var active: Bool
        var summary: String
        var facility: String
        var ratio: Double
        var floorValue: Double
        var quantity: Int
        var status: DefaultCredentialWindowStatus

        init(code: String, label: String, graceDays: Int, active: Bool, summary: String, facility: String, ratio: Double, floorValue: Double, quantity: Int, status: DefaultCredentialWindowStatus) {
            self.code = code
            self.label = label
            self.graceDays = graceDays
            self.active = active
            self.summary = summary
            self.facility = facility
            self.ratio = ratio
            self.floorValue = floorValue
            self.quantity = quantity
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

        func canMoveTo(_ next: DefaultCredentialWindowStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: DefaultCredentialWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default credential window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("default credential window") \(code)"
        }

        func weightedVolume() -> Double {
            return ((Double(graceDays) + Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultCredentialWindow {
            return DefaultCredentialWindow(
                code: code,
                label: label,
                graceDays: graceDays,
                active: active,
                summary: summary,
                facility: facility,
                ratio: ratio,
                floorValue: floorValue,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a default credential window in status created.
    static func newDefaultCredentialWindow(_ code: String, label: String) -> DefaultCredentialWindow {
        return DefaultCredentialWindow(
            code: code,
            label: label,
            graceDays: 0,
            active: false,
            summary: "",
            facility: "",
            ratio: 0.0,
            floorValue: 0.0,
            quantity: 0,
            status: DefaultCredentialWindowStatus.created
        )
    }
}
