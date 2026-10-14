import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a weighted program window is in its life cycle.
    enum WeightedProgramWindowStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A weighted program window as the program team keeps it.
    final class WeightedProgramWindow {
        var code: String
        var label: String
        var endsAt: Int
        var priority: Int
        var encounterID: String
        var procedureCode: String
        var createdAt: Int
        var updatedAt: Int
        var visitMinutes: Int
        var locale: String
        var quantity: Int
        var status: WeightedProgramWindowStatus

        init(code: String, label: String, endsAt: Int, priority: Int, encounterID: String, procedureCode: String, createdAt: Int, updatedAt: Int, visitMinutes: Int, locale: String, quantity: Int, status: WeightedProgramWindowStatus) {
            self.code = code
            self.label = label
            self.endsAt = endsAt
            self.priority = priority
            self.encounterID = encounterID
            self.procedureCode = procedureCode
            self.createdAt = createdAt
            self.updatedAt = updatedAt
            self.visitMinutes = visitMinutes
            self.locale = locale
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

        func canMoveTo(_ next: WeightedProgramWindowStatus) -> Bool {
            switch status {
            case .created:
                return next == WeightedProgramWindowStatus.published || next == WeightedProgramWindowStatus.retired
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: WeightedProgramWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted program window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func weightedTotal() -> Double {
            return ((Double(updatedAt) + Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> WeightedProgramWindow {
            return WeightedProgramWindow(
                code: code,
                label: label,
                endsAt: endsAt,
                priority: priority,
                encounterID: encounterID,
                procedureCode: procedureCode,
                createdAt: createdAt,
                updatedAt: updatedAt,
                visitMinutes: visitMinutes,
                locale: locale,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a weighted program window in status created.
    static func newWeightedProgramWindow(_ code: String, label: String) -> WeightedProgramWindow {
        return WeightedProgramWindow(
            code: code,
            label: label,
            endsAt: 0,
            priority: 0,
            encounterID: "",
            procedureCode: "",
            createdAt: 0,
            updatedAt: 0,
            visitMinutes: 0,
            locale: "",
            quantity: 0,
            status: WeightedProgramWindowStatus.created
        )
    }
}
