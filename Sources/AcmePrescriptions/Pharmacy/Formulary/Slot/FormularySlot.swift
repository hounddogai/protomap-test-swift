import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a formulary slot is in its life cycle.
    enum FormularySlotStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A formulary slot as the formulary team keeps it.
    final class FormularySlot {
        var code: String
        var title: String
        var externalRef: String
        var phone: String
        var source: String
        var category: String
        var batchSize: Int
        var startsAt: Int
        var status: FormularySlotStatus

        init(code: String, title: String, externalRef: String, phone: String, source: String, category: String, batchSize: Int, startsAt: Int, status: FormularySlotStatus) {
            self.code = code
            self.title = title
            self.externalRef = externalRef
            self.phone = phone
            self.source = source
            self.category = category
            self.batchSize = batchSize
            self.startsAt = startsAt
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

        func canMoveTo(_ next: FormularySlotStatus) -> Bool {
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
                return next == FormularySlotStatus.closed
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == FormularySlotStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FormularySlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("formulary slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("formulary slot") \(code)"
        }

        func weightedValue() -> Double {
            return ((Double(batchSize) + Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> FormularySlot {
            return FormularySlot(
                code: code,
                title: title,
                externalRef: externalRef,
                phone: phone,
                source: source,
                category: category,
                batchSize: batchSize,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a formulary slot in status draft.
    static func newFormularySlot(_ code: String, title: String) -> FormularySlot {
        return FormularySlot(
            code: code,
            title: title,
            externalRef: "",
            phone: "",
            source: "",
            category: "",
            batchSize: 0,
            startsAt: 0,
            status: FormularySlotStatus.draft
        )
    }
}
