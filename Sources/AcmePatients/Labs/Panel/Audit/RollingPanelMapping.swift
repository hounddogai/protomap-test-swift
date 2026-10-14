import AcmePlatform
import Foundation

extension Labs {
    /// Where a rolling panel mapping is in its life cycle.
    enum RollingPanelMappingStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One rolling panel mapping, with what the planners need to act on it.
    final class RollingPanelMapping {
        var code: String
        var label: String
        var locale: String
        var floorValue: Double
        var country: String
        var ceiling: Double
        var retries: Int
        var expiresAt: Int
        var minimum: Double
        var timezone: String
        var status: RollingPanelMappingStatus

        init(code: String, label: String, locale: String, floorValue: Double, country: String, ceiling: Double, retries: Int, expiresAt: Int, minimum: Double, timezone: String, status: RollingPanelMappingStatus) {
            self.code = code
            self.label = label
            self.locale = locale
            self.floorValue = floorValue
            self.country = country
            self.ceiling = ceiling
            self.retries = retries
            self.expiresAt = expiresAt
            self.minimum = minimum
            self.timezone = timezone
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

        func canMoveTo(_ next: RollingPanelMappingStatus) -> Bool {
            switch status {
            case .new:
                return next == RollingPanelMappingStatus.queued
            case .queued:
                switch next {
                case .running, .failed:
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

        func moveTo(_ next: RollingPanelMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling panel mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func adjustedLoad() -> Double {
            return ((minimum - Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> RollingPanelMapping {
            return RollingPanelMapping(
                code: code,
                label: label,
                locale: locale,
                floorValue: floorValue,
                country: country,
                ceiling: ceiling,
                retries: retries,
                expiresAt: expiresAt,
                minimum: minimum,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a rolling panel mapping in status new.
    static func newRollingPanelMapping(_ code: String, label: String) -> RollingPanelMapping {
        return RollingPanelMapping(
            code: code,
            label: label,
            locale: "",
            floorValue: 0.0,
            country: "",
            ceiling: 0.0,
            retries: 0,
            expiresAt: 0,
            minimum: 0.0,
            timezone: "",
            status: RollingPanelMappingStatus.new
        )
    }
}
