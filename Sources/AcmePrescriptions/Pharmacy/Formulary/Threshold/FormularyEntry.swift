import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a formulary entry is in its life cycle.
    enum FormularyEntryStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a formulary entry and its current status.
    final class FormularyEntry {
        var code: String
        var label: String
        var ceiling: Double
        var payer: String
        var externalRef: String
        var summary: String
        var maximum: Double
        var tags: [String]
        var name: String
        var capacity: Int
        var status: FormularyEntryStatus

        init(code: String, label: String, ceiling: Double, payer: String, externalRef: String, summary: String, maximum: Double, tags: [String], name: String, capacity: Int, status: FormularyEntryStatus) {
            self.code = code
            self.label = label
            self.ceiling = ceiling
            self.payer = payer
            self.externalRef = externalRef
            self.summary = summary
            self.maximum = maximum
            self.tags = tags
            self.name = name
            self.capacity = capacity
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

        func canMoveTo(_ next: FormularyEntryStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == FormularyEntryStatus.suspended || next == FormularyEntryStatus.closed
            case .active:
                return next == FormularyEntryStatus.suspended || next == FormularyEntryStatus.closed
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

        func moveTo(_ next: FormularyEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("formulary entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedTotal() -> Double {
            return (Double(capacity) * maximum * 100).rounded() / 100
        }

        func copyValue() -> FormularyEntry {
            return FormularyEntry(
                code: code,
                label: label,
                ceiling: ceiling,
                payer: payer,
                externalRef: externalRef,
                summary: summary,
                maximum: maximum,
                tags: tags,
                name: name,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a formulary entry in status draft.
    static func newFormularyEntry(_ code: String, label: String) -> FormularyEntry {
        return FormularyEntry(
            code: code,
            label: label,
            ceiling: 0.0,
            payer: "",
            externalRef: "",
            summary: "",
            maximum: 0.0,
            tags: [],
            name: "",
            capacity: 0,
            status: FormularyEntryStatus.draft
        )
    }
}
