import AcmePlatform
import Foundation

extension Consent {
    /// Where a fallback revocation template is in its life cycle.
    enum FallbackRevocationTemplateStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A fallback revocation template. Its code is unique within a tenant.
    final class FallbackRevocationTemplate {
        var code: String
        var title: String
        var ceiling: Double
        var retries: Int
        var phone: String
        var attributes: [String: String]
        var status: FallbackRevocationTemplateStatus

        init(code: String, title: String, ceiling: Double, retries: Int, phone: String, attributes: [String: String], status: FallbackRevocationTemplateStatus) {
            self.code = code
            self.title = title
            self.ceiling = ceiling
            self.retries = retries
            self.phone = phone
            self.attributes = attributes
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

        func canMoveTo(_ next: FallbackRevocationTemplateStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == FallbackRevocationTemplateStatus.active || next == FallbackRevocationTemplateStatus.closed
            case .active:
                switch next {
                case .closed:
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

        func moveTo(_ next: FallbackRevocationTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback revocation template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
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

        func projectedValue() -> Double {
            return ((ceiling - Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> FallbackRevocationTemplate {
            return FallbackRevocationTemplate(
                code: code,
                title: title,
                ceiling: ceiling,
                retries: retries,
                phone: phone,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a fallback revocation template in status draft.
    static func newFallbackRevocationTemplate(_ code: String, title: String) -> FallbackRevocationTemplate {
        return FallbackRevocationTemplate(
            code: code,
            title: title,
            ceiling: 0.0,
            retries: 0,
            phone: "",
            attributes: [:],
            status: FallbackRevocationTemplateStatus.draft
        )
    }
}
