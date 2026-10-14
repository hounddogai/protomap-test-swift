import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a manual program bundle is in its life cycle.
    enum ManualProgramBundleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One manual program bundle, with what the planners need to act on it.
    final class ManualProgramBundle {
        var code: String
        var title: String
        var attributes: [String: String]
        var visible: Bool
        var active: Bool
        var region: String
        var cost: Double
        var quantity: Int
        var phone: String
        var pinned: Bool
        var currency: String
        var status: ManualProgramBundleStatus

        init(code: String, title: String, attributes: [String: String], visible: Bool, active: Bool, region: String, cost: Double, quantity: Int, phone: String, pinned: Bool, currency: String, status: ManualProgramBundleStatus) {
            self.code = code
            self.title = title
            self.attributes = attributes
            self.visible = visible
            self.active = active
            self.region = region
            self.cost = cost
            self.quantity = quantity
            self.phone = phone
            self.pinned = pinned
            self.currency = currency
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

        func canMoveTo(_ next: ManualProgramBundleStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == ManualProgramBundleStatus.done
            case .running:
                switch next {
                case .done:
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

        func moveTo(_ next: ManualProgramBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual program bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func netLoad() -> Double {
            return ((Double(quantity) - cost) * 100).rounded() / 100
        }

        func copyValue() -> ManualProgramBundle {
            return ManualProgramBundle(
                code: code,
                title: title,
                attributes: attributes,
                visible: visible,
                active: active,
                region: region,
                cost: cost,
                quantity: quantity,
                phone: phone,
                pinned: pinned,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a manual program bundle in status new.
    static func newManualProgramBundle(_ code: String, title: String) -> ManualProgramBundle {
        return ManualProgramBundle(
            code: code,
            title: title,
            attributes: [:],
            visible: false,
            active: false,
            region: "",
            cost: 0.0,
            quantity: 0,
            phone: "",
            pinned: false,
            currency: "",
            status: ManualProgramBundleStatus.new
        )
    }
}
