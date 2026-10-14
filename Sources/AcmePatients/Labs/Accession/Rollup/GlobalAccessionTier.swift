import AcmePlatform
import Foundation

extension Labs {
    /// Where a global accession tier is in its life cycle.
    enum GlobalAccessionTierStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A global accession tier. Its code is unique within a tenant.
    final class GlobalAccessionTier {
        var code: String
        var title: String
        var margin: Double
        var locale: String
        var windowDays: Int
        var ward: String
        var status: GlobalAccessionTierStatus

        init(code: String, title: String, margin: Double, locale: String, windowDays: Int, ward: String, status: GlobalAccessionTierStatus) {
            self.code = code
            self.title = title
            self.margin = margin
            self.locale = locale
            self.windowDays = windowDays
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

        func canMoveTo(_ next: GlobalAccessionTierStatus) -> Bool {
            switch status {
            case .new:
                return next == GlobalAccessionTierStatus.running || next == GlobalAccessionTierStatus.failed
            case .queued:
                return next == GlobalAccessionTierStatus.done
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

        func moveTo(_ next: GlobalAccessionTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global accession tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("global accession tier") \(code)"
        }

        func effectiveExposure() -> Double {
            return ((margin - Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalAccessionTier {
            return GlobalAccessionTier(
                code: code,
                title: title,
                margin: margin,
                locale: locale,
                windowDays: windowDays,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a global accession tier in status new.
    static func newGlobalAccessionTier(_ code: String, title: String) -> GlobalAccessionTier {
        return GlobalAccessionTier(
            code: code,
            title: title,
            margin: 0.0,
            locale: "",
            windowDays: 0,
            ward: "",
            status: GlobalAccessionTierStatus.new
        )
    }
}
