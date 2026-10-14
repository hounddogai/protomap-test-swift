import AcmePlatform
import Foundation

extension Consent {
    /// Where a lenient proxy template is in its life cycle.
    enum LenientProxyTemplateStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a lenient proxy template and its current status.
    final class LenientProxyTemplate {
        var code: String
        var name: String
        var tags: [String]
        var refills: Int
        var country: String
        var ward: String
        var status: LenientProxyTemplateStatus

        init(code: String, name: String, tags: [String], refills: Int, country: String, ward: String, status: LenientProxyTemplateStatus) {
            self.code = code
            self.name = name
            self.tags = tags
            self.refills = refills
            self.country = country
            self.ward = ward
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

        func canMoveTo(_ next: LenientProxyTemplateStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .reopened, .archived:
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
                return next == LenientProxyTemplateStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientProxyTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient proxy template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return Double(refills)
        }

        func copyValue() -> LenientProxyTemplate {
            return LenientProxyTemplate(
                code: code,
                name: name,
                tags: tags,
                refills: refills,
                country: country,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a lenient proxy template in status open.
    static func newLenientProxyTemplate(_ code: String, name: String) -> LenientProxyTemplate {
        return LenientProxyTemplate(
            code: code,
            name: name,
            tags: [],
            refills: 0,
            country: "",
            ward: "",
            status: LenientProxyTemplateStatus.`open`
        )
    }
}
