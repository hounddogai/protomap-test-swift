import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a order set assignment is in its life cycle.
    enum OrderSetAssignmentStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A order set assignment as the order set team keeps it.
    final class OrderSetAssignment {
        var code: String
        var name: String
        var windowDays: Int
        var limit: Int
        var dosageMg: Double
        var minimum: Double
        var locale: String
        var refills: Int
        var status: OrderSetAssignmentStatus

        init(code: String, name: String, windowDays: Int, limit: Int, dosageMg: Double, minimum: Double, locale: String, refills: Int, status: OrderSetAssignmentStatus) {
            self.code = code
            self.name = name
            self.windowDays = windowDays
            self.limit = limit
            self.dosageMg = dosageMg
            self.minimum = minimum
            self.locale = locale
            self.refills = refills
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

        func canMoveTo(_ next: OrderSetAssignmentStatus) -> Bool {
            switch status {
            case .draft:
                return next == OrderSetAssignmentStatus.active || next == OrderSetAssignmentStatus.suspended
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == OrderSetAssignmentStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: OrderSetAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("order set assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func adjustedValue() -> Double {
            return ((Double(limit) + Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> OrderSetAssignment {
            return OrderSetAssignment(
                code: code,
                name: name,
                windowDays: windowDays,
                limit: limit,
                dosageMg: dosageMg,
                minimum: minimum,
                locale: locale,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a order set assignment in status draft.
    static func newOrderSetAssignment(_ code: String, name: String) -> OrderSetAssignment {
        return OrderSetAssignment(
            code: code,
            name: name,
            windowDays: 0,
            limit: 0,
            dosageMg: 0.0,
            minimum: 0.0,
            locale: "",
            refills: 0,
            status: OrderSetAssignmentStatus.draft
        )
    }
}
