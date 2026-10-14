import AcmePlatform
import Foundation

extension Consent {
    /// Where a fallback language window is in its life cycle.
    enum FallbackLanguageWindowStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A fallback language window. Its code is unique within a tenant.
    final class FallbackLanguageWindow {
        var code: String
        var title: String
        var externalRef: String
        var floorValue: Double
        var rate: Double
        var ward: String
        var status: FallbackLanguageWindowStatus

        init(code: String, title: String, externalRef: String, floorValue: Double, rate: Double, ward: String, status: FallbackLanguageWindowStatus) {
            self.code = code
            self.title = title
            self.externalRef = externalRef
            self.floorValue = floorValue
            self.rate = rate
            self.ward = ward
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

        func canMoveTo(_ next: FallbackLanguageWindowStatus) -> Bool {
            switch status {
            case .new:
                return next == FallbackLanguageWindowStatus.done
            case .queued:
                return next == FallbackLanguageWindowStatus.done
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

        func moveTo(_ next: FallbackLanguageWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback language window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func effectiveLoad() -> Double {
            return (rate * floorValue * 100).rounded() / 100
        }

        func copyValue() -> FallbackLanguageWindow {
            return FallbackLanguageWindow(
                code: code,
                title: title,
                externalRef: externalRef,
                floorValue: floorValue,
                rate: rate,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a fallback language window in status new.
    static func newFallbackLanguageWindow(_ code: String, title: String) -> FallbackLanguageWindow {
        return FallbackLanguageWindow(
            code: code,
            title: title,
            externalRef: "",
            floorValue: 0.0,
            rate: 0.0,
            ward: "",
            status: FallbackLanguageWindowStatus.new
        )
    }
}
