import AcmePlatform
import Foundation

extension Labs {
    /// Where a regional result digest is in its life cycle.
    enum RegionalResultDigestStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One regional result digest, with what the planners need to act on it.
    final class RegionalResultDigest {
        var code: String
        var label: String
        var visible: Bool
        var visitMinutes: Int
        var allergy: String
        var timezone: String
        var budget: Double
        var description: String
        var locale: String
        var status: RegionalResultDigestStatus

        init(code: String, label: String, visible: Bool, visitMinutes: Int, allergy: String, timezone: String, budget: Double, description: String, locale: String, status: RegionalResultDigestStatus) {
            self.code = code
            self.label = label
            self.visible = visible
            self.visitMinutes = visitMinutes
            self.allergy = allergy
            self.timezone = timezone
            self.budget = budget
            self.description = description
            self.locale = locale
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RegionalResultDigestStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: RegionalResultDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional result digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func effectiveLoad() -> Double {
            return ((budget - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalResultDigest {
            return RegionalResultDigest(
                code: code,
                label: label,
                visible: visible,
                visitMinutes: visitMinutes,
                allergy: allergy,
                timezone: timezone,
                budget: budget,
                description: description,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a regional result digest in status proposed.
    static func newRegionalResultDigest(_ code: String, label: String) -> RegionalResultDigest {
        return RegionalResultDigest(
            code: code,
            label: label,
            visible: false,
            visitMinutes: 0,
            allergy: "",
            timezone: "",
            budget: 0.0,
            description: "",
            locale: "",
            status: RegionalResultDigestStatus.proposed
        )
    }
}
