import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a seasonal task threshold is in its life cycle.
    enum SeasonalTaskThresholdStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a seasonal task threshold and its current status.
    final class SeasonalTaskThreshold {
        var code: String
        var name: String
        var revision: Int
        var archived: Bool
        var phone: String
        var contactEmail: String
        var discount: Double
        var status: SeasonalTaskThresholdStatus

        init(code: String, name: String, revision: Int, archived: Bool, phone: String, contactEmail: String, discount: Double, status: SeasonalTaskThresholdStatus) {
            self.code = code
            self.name = name
            self.revision = revision
            self.archived = archived
            self.phone = phone
            self.contactEmail = contactEmail
            self.discount = discount
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

        func canMoveTo(_ next: SeasonalTaskThresholdStatus) -> Bool {
            switch status {
            case .draft:
                return next == SeasonalTaskThresholdStatus.closed
            case .pending:
                return next == SeasonalTaskThresholdStatus.active || next == SeasonalTaskThresholdStatus.suspended
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == SeasonalTaskThresholdStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalTaskThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal task threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func effectiveVolume() -> Double {
            return ((discount + Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalTaskThreshold {
            return SeasonalTaskThreshold(
                code: code,
                name: name,
                revision: revision,
                archived: archived,
                phone: phone,
                contactEmail: contactEmail,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a seasonal task threshold in status draft.
    static func newSeasonalTaskThreshold(_ code: String, name: String) -> SeasonalTaskThreshold {
        return SeasonalTaskThreshold(
            code: code,
            name: name,
            revision: 0,
            archived: false,
            phone: "",
            contactEmail: "",
            discount: 0.0,
            status: SeasonalTaskThresholdStatus.draft
        )
    }
}
