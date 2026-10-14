import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a capped bed board record is in its life cycle.
    enum CappedBedBoardRecordStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A capped bed board record as the bed board team keeps it.
    final class CappedBedBoardRecord {
        var code: String
        var title: String
        var segment: String
        var currency: String
        var visible: Bool
        var archived: Bool
        var country: String
        var limit: Int
        var category: String
        var copay: Double
        var status: CappedBedBoardRecordStatus

        init(code: String, title: String, segment: String, currency: String, visible: Bool, archived: Bool, country: String, limit: Int, category: String, copay: Double, status: CappedBedBoardRecordStatus) {
            self.code = code
            self.title = title
            self.segment = segment
            self.currency = currency
            self.visible = visible
            self.archived = archived
            self.country = country
            self.limit = limit
            self.category = category
            self.copay = copay
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

        func canMoveTo(_ next: CappedBedBoardRecordStatus) -> Bool {
            switch status {
            case .draft:
                return next == CappedBedBoardRecordStatus.pending || next == CappedBedBoardRecordStatus.closed
            case .pending:
                switch next {
                case .suspended:
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
                return next == CappedBedBoardRecordStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedBedBoardRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped bed board record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("capped bed board record") \(code)"
        }

        func adjustedExposure() -> Double {
            return ((copay - Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> CappedBedBoardRecord {
            return CappedBedBoardRecord(
                code: code,
                title: title,
                segment: segment,
                currency: currency,
                visible: visible,
                archived: archived,
                country: country,
                limit: limit,
                category: category,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a capped bed board record in status draft.
    static func newCappedBedBoardRecord(_ code: String, title: String) -> CappedBedBoardRecord {
        return CappedBedBoardRecord(
            code: code,
            title: title,
            segment: "",
            currency: "",
            visible: false,
            archived: false,
            country: "",
            limit: 0,
            category: "",
            copay: 0.0,
            status: CappedBedBoardRecordStatus.draft
        )
    }
}
