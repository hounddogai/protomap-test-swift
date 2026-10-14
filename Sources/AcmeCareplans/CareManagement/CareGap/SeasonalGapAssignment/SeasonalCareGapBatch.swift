import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a seasonal care gap batch is in its life cycle.
    enum SeasonalCareGapBatchStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One seasonal care gap batch, with what the planners need to act on it.
    final class SeasonalCareGapBatch {
        var code: String
        var title: String
        var contactEmail: String
        var timezone: String
        var retries: Int
        var approved: Bool
        var status: SeasonalCareGapBatchStatus

        init(code: String, title: String, contactEmail: String, timezone: String, retries: Int, approved: Bool, status: SeasonalCareGapBatchStatus) {
            self.code = code
            self.title = title
            self.contactEmail = contactEmail
            self.timezone = timezone
            self.retries = retries
            self.approved = approved
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

        func canMoveTo(_ next: SeasonalCareGapBatchStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: SeasonalCareGapBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal care gap batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func measuredValue() -> Double {
            return Double(retries)
        }

        func copyValue() -> SeasonalCareGapBatch {
            return SeasonalCareGapBatch(
                code: code,
                title: title,
                contactEmail: contactEmail,
                timezone: timezone,
                retries: retries,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a seasonal care gap batch in status new.
    static func newSeasonalCareGapBatch(_ code: String, title: String) -> SeasonalCareGapBatch {
        return SeasonalCareGapBatch(
            code: code,
            title: title,
            contactEmail: "",
            timezone: "",
            retries: 0,
            approved: false,
            status: SeasonalCareGapBatchStatus.new
        )
    }
}
