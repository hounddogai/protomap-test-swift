import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a global bed board manifest is in its life cycle.
    enum GlobalBedBoardManifestStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A global bed board manifest. Its code is unique within a tenant.
    final class GlobalBedBoardManifest {
        var code: String
        var label: String
        var ownerID: String
        var cost: Double
        var expiresAt: Int
        var quantity: Int
        var refills: Int
        var sequence: Int
        var status: GlobalBedBoardManifestStatus

        init(code: String, label: String, ownerID: String, cost: Double, expiresAt: Int, quantity: Int, refills: Int, sequence: Int, status: GlobalBedBoardManifestStatus) {
            self.code = code
            self.label = label
            self.ownerID = ownerID
            self.cost = cost
            self.expiresAt = expiresAt
            self.quantity = quantity
            self.refills = refills
            self.sequence = sequence
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GlobalBedBoardManifestStatus) -> Bool {
            switch status {
            case .planned:
                return next == GlobalBedBoardManifestStatus.inProgress || next == GlobalBedBoardManifestStatus.completed
            case .scheduled:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: GlobalBedBoardManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global bed board manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func weightedValue() -> Double {
            return (Double(sequence) * cost * 100).rounded() / 100
        }

        func copyValue() -> GlobalBedBoardManifest {
            return GlobalBedBoardManifest(
                code: code,
                label: label,
                ownerID: ownerID,
                cost: cost,
                expiresAt: expiresAt,
                quantity: quantity,
                refills: refills,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a global bed board manifest in status planned.
    static func newGlobalBedBoardManifest(_ code: String, label: String) -> GlobalBedBoardManifest {
        return GlobalBedBoardManifest(
            code: code,
            label: label,
            ownerID: "",
            cost: 0.0,
            expiresAt: 0,
            quantity: 0,
            refills: 0,
            sequence: 0,
            status: GlobalBedBoardManifestStatus.planned
        )
    }
}
