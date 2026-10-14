import AcmePlatform
import Foundation

extension Imaging {
    /// Where a care protocol segment is in its life cycle.
    enum CareProtocolSegmentStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A care protocol segment as the care protocol team keeps it.
    final class CareProtocolSegment {
        var code: String
        var name: String
        var quantity: Int
        var clinicianID: String
        var discount: Double
        var locale: String
        var budget: Double
        var externalRef: String
        var priority: Int
        var status: CareProtocolSegmentStatus

        init(code: String, name: String, quantity: Int, clinicianID: String, discount: Double, locale: String, budget: Double, externalRef: String, priority: Int, status: CareProtocolSegmentStatus) {
            self.code = code
            self.name = name
            self.quantity = quantity
            self.clinicianID = clinicianID
            self.discount = discount
            self.locale = locale
            self.budget = budget
            self.externalRef = externalRef
            self.priority = priority
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

        func canMoveTo(_ next: CareProtocolSegmentStatus) -> Bool {
            switch status {
            case .draft:
                return next == CareProtocolSegmentStatus.pending || next == CareProtocolSegmentStatus.closed
            case .pending:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == CareProtocolSegmentStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareProtocolSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("care protocol segment") \(code)"
        }

        func netVolume() -> Double {
            return ((Double(quantity) + budget) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolSegment {
            return CareProtocolSegment(
                code: code,
                name: name,
                quantity: quantity,
                clinicianID: clinicianID,
                discount: discount,
                locale: locale,
                budget: budget,
                externalRef: externalRef,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a care protocol segment in status draft.
    static func newCareProtocolSegment(_ code: String, name: String) -> CareProtocolSegment {
        return CareProtocolSegment(
            code: code,
            name: name,
            quantity: 0,
            clinicianID: "",
            discount: 0.0,
            locale: "",
            budget: 0.0,
            externalRef: "",
            priority: 0,
            status: CareProtocolSegmentStatus.draft
        )
    }
}
