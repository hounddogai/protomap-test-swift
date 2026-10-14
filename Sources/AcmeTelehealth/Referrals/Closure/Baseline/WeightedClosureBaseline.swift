import AcmePlatform
import Foundation

extension Referrals {
    /// Where a weighted closure baseline is in its life cycle.
    enum WeightedClosureBaselineStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One weighted closure baseline, with what the planners need to act on it.
    final class WeightedClosureBaseline {
        var code: String
        var name: String
        var summary: String
        var visible: Bool
        var phone: String
        var diagnosisCode: String
        var notes: String
        var quantity: Int
        var status: WeightedClosureBaselineStatus

        init(code: String, name: String, summary: String, visible: Bool, phone: String, diagnosisCode: String, notes: String, quantity: Int, status: WeightedClosureBaselineStatus) {
            self.code = code
            self.name = name
            self.summary = summary
            self.visible = visible
            self.phone = phone
            self.diagnosisCode = diagnosisCode
            self.notes = notes
            self.quantity = quantity
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

        func canMoveTo(_ next: WeightedClosureBaselineStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == WeightedClosureBaselineStatus.published
            case .published:
                return next == WeightedClosureBaselineStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedClosureBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted closure baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> WeightedClosureBaseline {
            return WeightedClosureBaseline(
                code: code,
                name: name,
                summary: summary,
                visible: visible,
                phone: phone,
                diagnosisCode: diagnosisCode,
                notes: notes,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a weighted closure baseline in status created.
    static func newWeightedClosureBaseline(_ code: String, name: String) -> WeightedClosureBaseline {
        return WeightedClosureBaseline(
            code: code,
            name: name,
            summary: "",
            visible: false,
            phone: "",
            diagnosisCode: "",
            notes: "",
            quantity: 0,
            status: WeightedClosureBaselineStatus.created
        )
    }
}
