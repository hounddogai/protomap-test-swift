import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a capped transfer threshold is in its life cycle.
    enum CappedTransferThresholdStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a capped transfer threshold and its current status.
    final class CappedTransferThreshold {
        var code: String
        var title: String
        var procedureCode: String
        var visible: Bool
        var archived: Bool
        var category: String
        var copay: Double
        var ward: String
        var score: Double
        var active: Bool
        var tags: [String]
        var status: CappedTransferThresholdStatus

        init(code: String, title: String, procedureCode: String, visible: Bool, archived: Bool, category: String, copay: Double, ward: String, score: Double, active: Bool, tags: [String], status: CappedTransferThresholdStatus) {
            self.code = code
            self.title = title
            self.procedureCode = procedureCode
            self.visible = visible
            self.archived = archived
            self.category = category
            self.copay = copay
            self.ward = ward
            self.score = score
            self.active = active
            self.tags = tags
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CappedTransferThresholdStatus) -> Bool {
            switch status {
            case .`open`:
                return next == CappedTransferThresholdStatus.inReview || next == CappedTransferThresholdStatus.archived
            case .inReview:
                return next == CappedTransferThresholdStatus.resolved
            case .resolved:
                return next == CappedTransferThresholdStatus.reopened
            case .reopened:
                return next == CappedTransferThresholdStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedTransferThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped transfer threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("capped transfer threshold") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveTotal() -> Double {
            return ((copay - score) * 100).rounded() / 100
        }

        func copyValue() -> CappedTransferThreshold {
            return CappedTransferThreshold(
                code: code,
                title: title,
                procedureCode: procedureCode,
                visible: visible,
                archived: archived,
                category: category,
                copay: copay,
                ward: ward,
                score: score,
                active: active,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a capped transfer threshold in status open.
    static func newCappedTransferThreshold(_ code: String, title: String) -> CappedTransferThreshold {
        return CappedTransferThreshold(
            code: code,
            title: title,
            procedureCode: "",
            visible: false,
            archived: false,
            category: "",
            copay: 0.0,
            ward: "",
            score: 0.0,
            active: false,
            tags: [],
            status: CappedTransferThresholdStatus.`open`
        )
    }
}
