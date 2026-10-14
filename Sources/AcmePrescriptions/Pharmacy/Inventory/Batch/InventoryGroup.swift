import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a inventory group is in its life cycle.
    enum InventoryGroupStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A inventory group as the inventory team keeps it.
    final class InventoryGroup {
        var code: String
        var label: String
        var segment: String
        var attempts: Int
        var score: Double
        var currency: String
        var createdAt: Int
        var name: String
        var sequence: Int
        var ceiling: Double
        var status: InventoryGroupStatus

        init(code: String, label: String, segment: String, attempts: Int, score: Double, currency: String, createdAt: Int, name: String, sequence: Int, ceiling: Double, status: InventoryGroupStatus) {
            self.code = code
            self.label = label
            self.segment = segment
            self.attempts = attempts
            self.score = score
            self.currency = currency
            self.createdAt = createdAt
            self.name = name
            self.sequence = sequence
            self.ceiling = ceiling
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

        func canMoveTo(_ next: InventoryGroupStatus) -> Bool {
            switch status {
            case .draft:
                return next == InventoryGroupStatus.pending || next == InventoryGroupStatus.suspended
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == InventoryGroupStatus.suspended
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

        func moveTo(_ next: InventoryGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("inventory group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func projectedExposure() -> Double {
            return ((Double(createdAt) + score) * 100).rounded() / 100
        }

        func copyValue() -> InventoryGroup {
            return InventoryGroup(
                code: code,
                label: label,
                segment: segment,
                attempts: attempts,
                score: score,
                currency: currency,
                createdAt: createdAt,
                name: name,
                sequence: sequence,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a inventory group in status draft.
    static func newInventoryGroup(_ code: String, label: String) -> InventoryGroup {
        return InventoryGroup(
            code: code,
            label: label,
            segment: "",
            attempts: 0,
            score: 0.0,
            currency: "",
            createdAt: 0,
            name: "",
            sequence: 0,
            ceiling: 0.0,
            status: InventoryGroupStatus.draft
        )
    }
}
