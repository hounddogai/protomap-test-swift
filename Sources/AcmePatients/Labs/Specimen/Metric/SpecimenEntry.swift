import AcmePlatform
import Foundation

extension Labs {
    /// Where a specimen entry is in its life cycle.
    enum SpecimenEntryStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a specimen entry and its current status.
    final class SpecimenEntry {
        var code: String
        var label: String
        var source: String
        var updatedAt: Int
        var segment: String
        var phone: String
        var status: SpecimenEntryStatus

        init(code: String, label: String, source: String, updatedAt: Int, segment: String, phone: String, status: SpecimenEntryStatus) {
            self.code = code
            self.label = label
            self.source = source
            self.updatedAt = updatedAt
            self.segment = segment
            self.phone = phone
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

        func canMoveTo(_ next: SpecimenEntryStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == SpecimenEntryStatus.active || next == SpecimenEntryStatus.suspended
            case .active:
                return next == SpecimenEntryStatus.closed
            case .suspended:
                return next == SpecimenEntryStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SpecimenEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("specimen entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("specimen entry") \(code)"
        }

        func measuredValue() -> Double {
            return Double(updatedAt)
        }

        func copyValue() -> SpecimenEntry {
            return SpecimenEntry(
                code: code,
                label: label,
                source: source,
                updatedAt: updatedAt,
                segment: segment,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a specimen entry in status draft.
    static func newSpecimenEntry(_ code: String, label: String) -> SpecimenEntry {
        return SpecimenEntry(
            code: code,
            label: label,
            source: "",
            updatedAt: 0,
            segment: "",
            phone: "",
            status: SpecimenEntryStatus.draft
        )
    }
}
