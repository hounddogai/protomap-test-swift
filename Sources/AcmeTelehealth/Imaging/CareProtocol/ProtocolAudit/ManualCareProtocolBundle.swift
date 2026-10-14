import AcmePlatform
import Foundation

extension Imaging {
    /// Where a manual care protocol bundle is in its life cycle.
    enum ManualCareProtocolBundleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A manual care protocol bundle. Its code is unique within a tenant.
    final class ManualCareProtocolBundle {
        var code: String
        var title: String
        var country: String
        var facility: String
        var segment: String
        var quantity: Int
        var status: ManualCareProtocolBundleStatus

        init(code: String, title: String, country: String, facility: String, segment: String, quantity: Int, status: ManualCareProtocolBundleStatus) {
            self.code = code
            self.title = title
            self.country = country
            self.facility = facility
            self.segment = segment
            self.quantity = quantity
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

        func canMoveTo(_ next: ManualCareProtocolBundleStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == ManualCareProtocolBundleStatus.draining || next == ManualCareProtocolBundleStatus.stopped
            case .draining:
                return next == ManualCareProtocolBundleStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualCareProtocolBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual care protocol bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> ManualCareProtocolBundle {
            return ManualCareProtocolBundle(
                code: code,
                title: title,
                country: country,
                facility: facility,
                segment: segment,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a manual care protocol bundle in status idle.
    static func newManualCareProtocolBundle(_ code: String, title: String) -> ManualCareProtocolBundle {
        return ManualCareProtocolBundle(
            code: code,
            title: title,
            country: "",
            facility: "",
            segment: "",
            quantity: 0,
            status: ManualCareProtocolBundleStatus.idle
        )
    }
}
