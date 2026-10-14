import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a adaptive substitution bundle is in its life cycle.
    enum AdaptiveSubstitutionBundleStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One adaptive substitution bundle, with what the planners need to act on it.
    final class AdaptiveSubstitutionBundle {
        var code: String
        var title: String
        var procedureCode: String
        var channel: String
        var segment: String
        var name: String
        var source: String
        var visible: Bool
        var attributes: [String: String]
        var quantity: Int
        var status: AdaptiveSubstitutionBundleStatus

        init(code: String, title: String, procedureCode: String, channel: String, segment: String, name: String, source: String, visible: Bool, attributes: [String: String], quantity: Int, status: AdaptiveSubstitutionBundleStatus) {
            self.code = code
            self.title = title
            self.procedureCode = procedureCode
            self.channel = channel
            self.segment = segment
            self.name = name
            self.source = source
            self.visible = visible
            self.attributes = attributes
            self.quantity = quantity
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

        func canMoveTo(_ next: AdaptiveSubstitutionBundleStatus) -> Bool {
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
                return next == AdaptiveSubstitutionBundleStatus.revoked || next == AdaptiveSubstitutionBundleStatus.expired
            case .revoked:
                return next == AdaptiveSubstitutionBundleStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveSubstitutionBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive substitution bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("adaptive substitution bundle") \(code)"
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

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> AdaptiveSubstitutionBundle {
            return AdaptiveSubstitutionBundle(
                code: code,
                title: title,
                procedureCode: procedureCode,
                channel: channel,
                segment: segment,
                name: name,
                source: source,
                visible: visible,
                attributes: attributes,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a adaptive substitution bundle in status requested.
    static func newAdaptiveSubstitutionBundle(_ code: String, title: String) -> AdaptiveSubstitutionBundle {
        return AdaptiveSubstitutionBundle(
            code: code,
            title: title,
            procedureCode: "",
            channel: "",
            segment: "",
            name: "",
            source: "",
            visible: false,
            attributes: [:],
            quantity: 0,
            status: AdaptiveSubstitutionBundleStatus.requested
        )
    }
}
