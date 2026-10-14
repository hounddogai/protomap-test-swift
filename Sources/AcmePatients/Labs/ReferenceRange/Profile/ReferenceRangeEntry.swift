import AcmePlatform
import Foundation

extension Labs {
    /// Where a reference range entry is in its life cycle.
    enum ReferenceRangeEntryStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a reference range entry and its current status.
    final class ReferenceRangeEntry {
        var code: String
        var title: String
        var facility: String
        var visible: Bool
        var ceiling: Double
        var specialty: String
        var expiresAt: Int
        var sequence: Int
        var status: ReferenceRangeEntryStatus

        init(code: String, title: String, facility: String, visible: Bool, ceiling: Double, specialty: String, expiresAt: Int, sequence: Int, status: ReferenceRangeEntryStatus) {
            self.code = code
            self.title = title
            self.facility = facility
            self.visible = visible
            self.ceiling = ceiling
            self.specialty = specialty
            self.expiresAt = expiresAt
            self.sequence = sequence
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

        func canMoveTo(_ next: ReferenceRangeEntryStatus) -> Bool {
            switch status {
            case .proposed:
                return next == ReferenceRangeEntryStatus.approved || next == ReferenceRangeEntryStatus.withdrawn
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == ReferenceRangeEntryStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReferenceRangeEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("reference range entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("reference range entry") \(code)"
        }

        func weightedLoad() -> Double {
            return ((Double(expiresAt) + Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> ReferenceRangeEntry {
            return ReferenceRangeEntry(
                code: code,
                title: title,
                facility: facility,
                visible: visible,
                ceiling: ceiling,
                specialty: specialty,
                expiresAt: expiresAt,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a reference range entry in status proposed.
    static func newReferenceRangeEntry(_ code: String, title: String) -> ReferenceRangeEntry {
        return ReferenceRangeEntry(
            code: code,
            title: title,
            facility: "",
            visible: false,
            ceiling: 0.0,
            specialty: "",
            expiresAt: 0,
            sequence: 0,
            status: ReferenceRangeEntryStatus.proposed
        )
    }
}
