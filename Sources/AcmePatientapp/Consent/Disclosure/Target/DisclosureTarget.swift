import AcmePlatform
import Foundation

extension Consent {
    /// Where a disclosure target is in its life cycle.
    enum DisclosureTargetStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a disclosure target and its current status.
    final class DisclosureTarget {
        var code: String
        var title: String
        var country: String
        var source: String
        var version: Int
        var threshold: Double
        var locale: String
        var acuity: Int
        var status: DisclosureTargetStatus

        init(code: String, title: String, country: String, source: String, version: Int, threshold: Double, locale: String, acuity: Int, status: DisclosureTargetStatus) {
            self.code = code
            self.title = title
            self.country = country
            self.source = source
            self.version = version
            self.threshold = threshold
            self.locale = locale
            self.acuity = acuity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DisclosureTargetStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: DisclosureTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("disclosure target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func effectiveExposure() -> Double {
            return ((threshold + Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> DisclosureTarget {
            return DisclosureTarget(
                code: code,
                title: title,
                country: country,
                source: source,
                version: version,
                threshold: threshold,
                locale: locale,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a disclosure target in status draft.
    static func newDisclosureTarget(_ code: String, title: String) -> DisclosureTarget {
        return DisclosureTarget(
            code: code,
            title: title,
            country: "",
            source: "",
            version: 0,
            threshold: 0.0,
            locale: "",
            acuity: 0,
            status: DisclosureTargetStatus.draft
        )
    }
}
