import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a weighted care gap draft is in its life cycle.
    enum WeightedCareGapDraftStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A weighted care gap draft as the care gap team keeps it.
    final class WeightedCareGapDraft {
        var code: String
        var title: String
        var country: String
        var refills: Int
        var procedureCode: String
        var contactEmail: String
        var status: WeightedCareGapDraftStatus

        init(code: String, title: String, country: String, refills: Int, procedureCode: String, contactEmail: String, status: WeightedCareGapDraftStatus) {
            self.code = code
            self.title = title
            self.country = country
            self.refills = refills
            self.procedureCode = procedureCode
            self.contactEmail = contactEmail
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WeightedCareGapDraftStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == WeightedCareGapDraftStatus.done
            case .running:
                return next == WeightedCareGapDraftStatus.done || next == WeightedCareGapDraftStatus.failed
            case .done:
                return next == WeightedCareGapDraftStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedCareGapDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted care gap draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return Double(refills)
        }

        func copyValue() -> WeightedCareGapDraft {
            return WeightedCareGapDraft(
                code: code,
                title: title,
                country: country,
                refills: refills,
                procedureCode: procedureCode,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a weighted care gap draft in status new.
    static func newWeightedCareGapDraft(_ code: String, title: String) -> WeightedCareGapDraft {
        return WeightedCareGapDraft(
            code: code,
            title: title,
            country: "",
            refills: 0,
            procedureCode: "",
            contactEmail: "",
            status: WeightedCareGapDraftStatus.new
        )
    }
}
