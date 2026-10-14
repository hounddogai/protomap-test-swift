import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a lenient cleaning metric is in its life cycle.
    enum LenientCleaningMetricStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A lenient cleaning metric. Its code is unique within a tenant.
    final class LenientCleaningMetric {
        var code: String
        var title: String
        var expiresAt: Int
        var visible: Bool
        var region: String
        var minimum: Double
        var createdAt: Int
        var facility: String
        var locale: String
        var attempts: Int
        var status: LenientCleaningMetricStatus

        init(code: String, title: String, expiresAt: Int, visible: Bool, region: String, minimum: Double, createdAt: Int, facility: String, locale: String, attempts: Int, status: LenientCleaningMetricStatus) {
            self.code = code
            self.title = title
            self.expiresAt = expiresAt
            self.visible = visible
            self.region = region
            self.minimum = minimum
            self.createdAt = createdAt
            self.facility = facility
            self.locale = locale
            self.attempts = attempts
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientCleaningMetricStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == LenientCleaningMetricStatus.revoked
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: LenientCleaningMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient cleaning metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func netLoad() -> Double {
            return ((Double(expiresAt) - Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> LenientCleaningMetric {
            return LenientCleaningMetric(
                code: code,
                title: title,
                expiresAt: expiresAt,
                visible: visible,
                region: region,
                minimum: minimum,
                createdAt: createdAt,
                facility: facility,
                locale: locale,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a lenient cleaning metric in status requested.
    static func newLenientCleaningMetric(_ code: String, title: String) -> LenientCleaningMetric {
        return LenientCleaningMetric(
            code: code,
            title: title,
            expiresAt: 0,
            visible: false,
            region: "",
            minimum: 0.0,
            createdAt: 0,
            facility: "",
            locale: "",
            attempts: 0,
            status: LenientCleaningMetricStatus.requested
        )
    }
}
