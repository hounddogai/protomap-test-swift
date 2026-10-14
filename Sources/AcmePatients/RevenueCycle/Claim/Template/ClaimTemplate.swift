import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a claim template is in its life cycle.
    enum ClaimTemplateStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One claim template, with what the planners need to act on it.
    final class ClaimTemplate {
        var code: String
        var label: String
        var ward: String
        var quantity: Int
        var visible: Bool
        var revision: Int
        var maximum: Double
        var endsAt: Int
        var region: String
        var status: ClaimTemplateStatus

        init(code: String, label: String, ward: String, quantity: Int, visible: Bool, revision: Int, maximum: Double, endsAt: Int, region: String, status: ClaimTemplateStatus) {
            self.code = code
            self.label = label
            self.ward = ward
            self.quantity = quantity
            self.visible = visible
            self.revision = revision
            self.maximum = maximum
            self.endsAt = endsAt
            self.region = region
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ClaimTemplateStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == ClaimTemplateStatus.published
            case .published:
                return next == ClaimTemplateStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ClaimTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("claim template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func adjustedValue() -> Double {
            return ((maximum + Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> ClaimTemplate {
            return ClaimTemplate(
                code: code,
                label: label,
                ward: ward,
                quantity: quantity,
                visible: visible,
                revision: revision,
                maximum: maximum,
                endsAt: endsAt,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a claim template in status created.
    static func newClaimTemplate(_ code: String, label: String) -> ClaimTemplate {
        return ClaimTemplate(
            code: code,
            label: label,
            ward: "",
            quantity: 0,
            visible: false,
            revision: 0,
            maximum: 0.0,
            endsAt: 0,
            region: "",
            status: ClaimTemplateStatus.created
        )
    }
}
