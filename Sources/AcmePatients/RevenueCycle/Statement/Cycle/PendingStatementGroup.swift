import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a pending statement group is in its life cycle.
    enum PendingStatementGroupStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A pending statement group as the statement team keeps it.
    final class PendingStatementGroup {
        var code: String
        var title: String
        var active: Bool
        var ceiling: Double
        var specialty: String
        var sequence: Int
        var durationMinutes: Int
        var weight: Double
        var capacity: Int
        var locale: String
        var status: PendingStatementGroupStatus

        init(code: String, title: String, active: Bool, ceiling: Double, specialty: String, sequence: Int, durationMinutes: Int, weight: Double, capacity: Int, locale: String, status: PendingStatementGroupStatus) {
            self.code = code
            self.title = title
            self.active = active
            self.ceiling = ceiling
            self.specialty = specialty
            self.sequence = sequence
            self.durationMinutes = durationMinutes
            self.weight = weight
            self.capacity = capacity
            self.locale = locale
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

        func canMoveTo(_ next: PendingStatementGroupStatus) -> Bool {
            switch status {
            case .proposed:
                return next == PendingStatementGroupStatus.approved || next == PendingStatementGroupStatus.rejected
            case .approved:
                return next == PendingStatementGroupStatus.withdrawn
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

        func moveTo(_ next: PendingStatementGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending statement group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func projectedVolume() -> Double {
            return ((weight + Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> PendingStatementGroup {
            return PendingStatementGroup(
                code: code,
                title: title,
                active: active,
                ceiling: ceiling,
                specialty: specialty,
                sequence: sequence,
                durationMinutes: durationMinutes,
                weight: weight,
                capacity: capacity,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a pending statement group in status proposed.
    static func newPendingStatementGroup(_ code: String, title: String) -> PendingStatementGroup {
        return PendingStatementGroup(
            code: code,
            title: title,
            active: false,
            ceiling: 0.0,
            specialty: "",
            sequence: 0,
            durationMinutes: 0,
            weight: 0.0,
            capacity: 0,
            locale: "",
            status: PendingStatementGroupStatus.proposed
        )
    }
}
