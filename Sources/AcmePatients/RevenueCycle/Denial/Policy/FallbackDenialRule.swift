import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a fallback denial rule is in its life cycle.
    enum FallbackDenialRuleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One fallback denial rule, with what the planners need to act on it.
    final class FallbackDenialRule {
        var code: String
        var label: String
        var attributes: [String: String]
        var expiresAt: Int
        var active: Bool
        var weight: Double
        var phone: String
        var windowDays: Int
        var status: FallbackDenialRuleStatus

        init(code: String, label: String, attributes: [String: String], expiresAt: Int, active: Bool, weight: Double, phone: String, windowDays: Int, status: FallbackDenialRuleStatus) {
            self.code = code
            self.label = label
            self.attributes = attributes
            self.expiresAt = expiresAt
            self.active = active
            self.weight = weight
            self.phone = phone
            self.windowDays = windowDays
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

        func canMoveTo(_ next: FallbackDenialRuleStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == FallbackDenialRuleStatus.suspended
            case .active:
                return next == FallbackDenialRuleStatus.suspended
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

        func moveTo(_ next: FallbackDenialRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback denial rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
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

        func effectiveVolume() -> Double {
            return ((weight - Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> FallbackDenialRule {
            return FallbackDenialRule(
                code: code,
                label: label,
                attributes: attributes,
                expiresAt: expiresAt,
                active: active,
                weight: weight,
                phone: phone,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a fallback denial rule in status draft.
    static func newFallbackDenialRule(_ code: String, label: String) -> FallbackDenialRule {
        return FallbackDenialRule(
            code: code,
            label: label,
            attributes: [:],
            expiresAt: 0,
            active: false,
            weight: 0.0,
            phone: "",
            windowDays: 0,
            status: FallbackDenialRuleStatus.draft
        )
    }
}
