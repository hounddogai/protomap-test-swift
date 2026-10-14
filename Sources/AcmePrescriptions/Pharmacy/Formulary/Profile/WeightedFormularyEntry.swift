import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a weighted formulary entry is in its life cycle.
    enum WeightedFormularyEntryStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One weighted formulary entry, with what the planners need to act on it.
    final class WeightedFormularyEntry {
        var code: String
        var title: String
        var updatedAt: Int
        var sequence: Int
        var visitMinutes: Int
        var amount: Double
        var visible: Bool
        var status: WeightedFormularyEntryStatus

        init(code: String, title: String, updatedAt: Int, sequence: Int, visitMinutes: Int, amount: Double, visible: Bool, status: WeightedFormularyEntryStatus) {
            self.code = code
            self.title = title
            self.updatedAt = updatedAt
            self.sequence = sequence
            self.visitMinutes = visitMinutes
            self.amount = amount
            self.visible = visible
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

        func canMoveTo(_ next: WeightedFormularyEntryStatus) -> Bool {
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
                return next == WeightedFormularyEntryStatus.withdrawn
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

        func moveTo(_ next: WeightedFormularyEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted formulary entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func projectedTotal() -> Double {
            return ((Double(visitMinutes) - Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> WeightedFormularyEntry {
            return WeightedFormularyEntry(
                code: code,
                title: title,
                updatedAt: updatedAt,
                sequence: sequence,
                visitMinutes: visitMinutes,
                amount: amount,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a weighted formulary entry in status proposed.
    static func newWeightedFormularyEntry(_ code: String, title: String) -> WeightedFormularyEntry {
        return WeightedFormularyEntry(
            code: code,
            title: title,
            updatedAt: 0,
            sequence: 0,
            visitMinutes: 0,
            amount: 0.0,
            visible: false,
            status: WeightedFormularyEntryStatus.proposed
        )
    }
}
