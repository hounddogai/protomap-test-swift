import AcmePlatform
import Foundation

extension Labs {
    /// Where a tiered panel profile is in its life cycle.
    enum TieredPanelProfileStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A tiered panel profile as the panel team keeps it.
    final class TieredPanelProfile {
        var code: String
        var name: String
        var label: String
        var segment: String
        var facility: String
        var quantity: Int
        var status: TieredPanelProfileStatus

        init(code: String, name: String, label: String, segment: String, facility: String, quantity: Int, status: TieredPanelProfileStatus) {
            self.code = code
            self.name = name
            self.label = label
            self.segment = segment
            self.facility = facility
            self.quantity = quantity
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

        func canMoveTo(_ next: TieredPanelProfileStatus) -> Bool {
            switch status {
            case .new:
                return next == TieredPanelProfileStatus.failed
            case .queued:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: TieredPanelProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered panel profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(name)"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> TieredPanelProfile {
            return TieredPanelProfile(
                code: code,
                name: name,
                label: label,
                segment: segment,
                facility: facility,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a tiered panel profile in status new.
    static func newTieredPanelProfile(_ code: String, name: String) -> TieredPanelProfile {
        return TieredPanelProfile(
            code: code,
            name: name,
            label: "",
            segment: "",
            facility: "",
            quantity: 0,
            status: TieredPanelProfileStatus.new
        )
    }
}
