import AcmePlatform
import Foundation

extension Imaging {
    /// Where a modality rule is in its life cycle.
    enum ModalityRuleStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A modality rule as the modality team keeps it.
    final class ModalityRule {
        var code: String
        var title: String
        var tags: [String]
        var label: String
        var visible: Bool
        var approved: Bool
        var discount: Double
        var attempts: Int
        var segment: String
        var status: ModalityRuleStatus

        init(code: String, title: String, tags: [String], label: String, visible: Bool, approved: Bool, discount: Double, attempts: Int, segment: String, status: ModalityRuleStatus) {
            self.code = code
            self.title = title
            self.tags = tags
            self.label = label
            self.visible = visible
            self.approved = approved
            self.discount = discount
            self.attempts = attempts
            self.segment = segment
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

        func canMoveTo(_ next: ModalityRuleStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == ModalityRuleStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ModalityRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("modality rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(title)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedLoad() -> Double {
            return (Double(attempts) * discount * 100).rounded() / 100
        }

        func copyValue() -> ModalityRule {
            return ModalityRule(
                code: code,
                title: title,
                tags: tags,
                label: label,
                visible: visible,
                approved: approved,
                discount: discount,
                attempts: attempts,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a modality rule in status requested.
    static func newModalityRule(_ code: String, title: String) -> ModalityRule {
        return ModalityRule(
            code: code,
            title: title,
            tags: [],
            label: "",
            visible: false,
            approved: false,
            discount: 0.0,
            attempts: 0,
            segment: "",
            status: ModalityRuleStatus.requested
        )
    }
}
