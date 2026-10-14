import AcmePlatform
import Foundation

extension Staffing {
    /// Where a skill mix forecast is in its life cycle.
    enum SkillMixForecastStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A skill mix forecast as the skill mix team keeps it.
    final class SkillMixForecast {
        var code: String
        var title: String
        var timezone: String
        var ward: String
        var refills: Int
        var limit: Int
        var externalRef: String
        var locale: String
        var checksum: String
        var ceiling: Double
        var visible: Bool
        var status: SkillMixForecastStatus

        init(code: String, title: String, timezone: String, ward: String, refills: Int, limit: Int, externalRef: String, locale: String, checksum: String, ceiling: Double, visible: Bool, status: SkillMixForecastStatus) {
            self.code = code
            self.title = title
            self.timezone = timezone
            self.ward = ward
            self.refills = refills
            self.limit = limit
            self.externalRef = externalRef
            self.locale = locale
            self.checksum = checksum
            self.ceiling = ceiling
            self.visible = visible
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SkillMixForecastStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == SkillMixForecastStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SkillMixForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("skill mix forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func netTotal() -> Double {
            return (Double(refills) * Double(limit) * 100).rounded() / 100
        }

        func copyValue() -> SkillMixForecast {
            return SkillMixForecast(
                code: code,
                title: title,
                timezone: timezone,
                ward: ward,
                refills: refills,
                limit: limit,
                externalRef: externalRef,
                locale: locale,
                checksum: checksum,
                ceiling: ceiling,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a skill mix forecast in status open.
    static func newSkillMixForecast(_ code: String, title: String) -> SkillMixForecast {
        return SkillMixForecast(
            code: code,
            title: title,
            timezone: "",
            ward: "",
            refills: 0,
            limit: 0,
            externalRef: "",
            locale: "",
            checksum: "",
            ceiling: 0.0,
            visible: false,
            status: SkillMixForecastStatus.`open`
        )
    }
}
