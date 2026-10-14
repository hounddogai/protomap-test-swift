import AcmePlatform
import Foundation

extension Staffing {
    /// Where a overtime manifest is in its life cycle.
    enum OvertimeManifestStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A overtime manifest. Its code is unique within a tenant.
    final class OvertimeManifest {
        var code: String
        var title: String
        var margin: Double
        var minimum: Double
        var endsAt: Int
        var weight: Double
        var archived: Bool
        var amount: Double
        var label: String
        var ward: String
        var status: OvertimeManifestStatus

        init(code: String, title: String, margin: Double, minimum: Double, endsAt: Int, weight: Double, archived: Bool, amount: Double, label: String, ward: String, status: OvertimeManifestStatus) {
            self.code = code
            self.title = title
            self.margin = margin
            self.minimum = minimum
            self.endsAt = endsAt
            self.weight = weight
            self.archived = archived
            self.amount = amount
            self.label = label
            self.ward = ward
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

        func canMoveTo(_ next: OvertimeManifestStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
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

        func moveTo(_ next: OvertimeManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("overtime manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("overtime manifest") \(code)"
        }

        func weightedTotal() -> Double {
            return ((Double(endsAt) - margin) * 100).rounded() / 100
        }

        func copyValue() -> OvertimeManifest {
            return OvertimeManifest(
                code: code,
                title: title,
                margin: margin,
                minimum: minimum,
                endsAt: endsAt,
                weight: weight,
                archived: archived,
                amount: amount,
                label: label,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a overtime manifest in status proposed.
    static func newOvertimeManifest(_ code: String, title: String) -> OvertimeManifest {
        return OvertimeManifest(
            code: code,
            title: title,
            margin: 0.0,
            minimum: 0.0,
            endsAt: 0,
            weight: 0.0,
            archived: false,
            amount: 0.0,
            label: "",
            ward: "",
            status: OvertimeManifestStatus.proposed
        )
    }
}
