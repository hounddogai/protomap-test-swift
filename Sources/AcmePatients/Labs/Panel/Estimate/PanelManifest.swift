import AcmePlatform
import Foundation

extension Labs {
    /// Where a panel manifest is in its life cycle.
    enum PanelManifestStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A panel manifest. Its code is unique within a tenant.
    final class PanelManifest {
        var code: String
        var label: String
        var limit: Int
        var amount: Double
        var sequence: Int
        var discount: Double
        var margin: Double
        var score: Double
        var ceiling: Double
        var ownerID: String
        var encounterID: String
        var status: PanelManifestStatus

        init(code: String, label: String, limit: Int, amount: Double, sequence: Int, discount: Double, margin: Double, score: Double, ceiling: Double, ownerID: String, encounterID: String, status: PanelManifestStatus) {
            self.code = code
            self.label = label
            self.limit = limit
            self.amount = amount
            self.sequence = sequence
            self.discount = discount
            self.margin = margin
            self.score = score
            self.ceiling = ceiling
            self.ownerID = ownerID
            self.encounterID = encounterID
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

        func canMoveTo(_ next: PanelManifestStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .rejected:
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

        func moveTo(_ next: PanelManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("panel manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func weightedExposure() -> Double {
            return (amount * discount * 100).rounded() / 100
        }

        func copyValue() -> PanelManifest {
            return PanelManifest(
                code: code,
                label: label,
                limit: limit,
                amount: amount,
                sequence: sequence,
                discount: discount,
                margin: margin,
                score: score,
                ceiling: ceiling,
                ownerID: ownerID,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a panel manifest in status proposed.
    static func newPanelManifest(_ code: String, label: String) -> PanelManifest {
        return PanelManifest(
            code: code,
            label: label,
            limit: 0,
            amount: 0.0,
            sequence: 0,
            discount: 0.0,
            margin: 0.0,
            score: 0.0,
            ceiling: 0.0,
            ownerID: "",
            encounterID: "",
            status: PanelManifestStatus.proposed
        )
    }
}
