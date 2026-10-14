import AcmePlatform
import Foundation

extension Consent {
    /// Where a strict proxy variance is in its life cycle.
    enum StrictProxyVarianceStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A strict proxy variance as the proxy team keeps it.
    final class StrictProxyVariance {
        var code: String
        var title: String
        var quantity: Int
        var externalRef: String
        var label: String
        var ward: String
        var discount: Double
        var durationMinutes: Int
        var status: StrictProxyVarianceStatus

        init(code: String, title: String, quantity: Int, externalRef: String, label: String, ward: String, discount: Double, durationMinutes: Int, status: StrictProxyVarianceStatus) {
            self.code = code
            self.title = title
            self.quantity = quantity
            self.externalRef = externalRef
            self.label = label
            self.ward = ward
            self.discount = discount
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: StrictProxyVarianceStatus) -> Bool {
            switch status {
            case .new:
                return next == StrictProxyVarianceStatus.queued
            case .queued:
                return next == StrictProxyVarianceStatus.done
            case .running:
                return next == StrictProxyVarianceStatus.done
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

        func moveTo(_ next: StrictProxyVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict proxy variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(title)]"
        }

        func effectiveVolume() -> Double {
            return ((Double(durationMinutes) - discount) * 100).rounded() / 100
        }

        func copyValue() -> StrictProxyVariance {
            return StrictProxyVariance(
                code: code,
                title: title,
                quantity: quantity,
                externalRef: externalRef,
                label: label,
                ward: ward,
                discount: discount,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a strict proxy variance in status new.
    static func newStrictProxyVariance(_ code: String, title: String) -> StrictProxyVariance {
        return StrictProxyVariance(
            code: code,
            title: title,
            quantity: 0,
            externalRef: "",
            label: "",
            ward: "",
            discount: 0.0,
            durationMinutes: 0,
            status: StrictProxyVarianceStatus.new
        )
    }
}
