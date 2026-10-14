import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a pending census allocation is in its life cycle.
    enum PendingCensusAllocationStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A pending census allocation. Its code is unique within a tenant.
    final class PendingCensusAllocation {
        var code: String
        var title: String
        var dosageMg: Double
        var tags: [String]
        var quantity: Int
        var locale: String
        var allergy: String
        var graceDays: Int
        var status: PendingCensusAllocationStatus

        init(code: String, title: String, dosageMg: Double, tags: [String], quantity: Int, locale: String, allergy: String, graceDays: Int, status: PendingCensusAllocationStatus) {
            self.code = code
            self.title = title
            self.dosageMg = dosageMg
            self.tags = tags
            self.quantity = quantity
            self.locale = locale
            self.allergy = allergy
            self.graceDays = graceDays
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

        func canMoveTo(_ next: PendingCensusAllocationStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == PendingCensusAllocationStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingCensusAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending census allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedVolume() -> Double {
            return ((dosageMg - Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> PendingCensusAllocation {
            return PendingCensusAllocation(
                code: code,
                title: title,
                dosageMg: dosageMg,
                tags: tags,
                quantity: quantity,
                locale: locale,
                allergy: allergy,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a pending census allocation in status draft.
    static func newPendingCensusAllocation(_ code: String, title: String) -> PendingCensusAllocation {
        return PendingCensusAllocation(
            code: code,
            title: title,
            dosageMg: 0.0,
            tags: [],
            quantity: 0,
            locale: "",
            allergy: "",
            graceDays: 0,
            status: PendingCensusAllocationStatus.draft
        )
    }
}
