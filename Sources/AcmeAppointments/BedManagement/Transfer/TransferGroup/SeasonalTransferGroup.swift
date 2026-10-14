import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a seasonal transfer group is in its life cycle.
    enum SeasonalTransferGroupStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A seasonal transfer group as the transfer team keeps it.
    final class SeasonalTransferGroup {
        var code: String
        var title: String
        var encounterID: String
        var discount: Double
        var tags: [String]
        var contactEmail: String
        var status: SeasonalTransferGroupStatus

        init(code: String, title: String, encounterID: String, discount: Double, tags: [String], contactEmail: String, status: SeasonalTransferGroupStatus) {
            self.code = code
            self.title = title
            self.encounterID = encounterID
            self.discount = discount
            self.tags = tags
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

        func canMoveTo(_ next: SeasonalTransferGroupStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == SeasonalTransferGroupStatus.running || next == SeasonalTransferGroupStatus.failed
            case .running:
                return next == SeasonalTransferGroupStatus.done || next == SeasonalTransferGroupStatus.failed
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

        func moveTo(_ next: SeasonalTransferGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal transfer group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return discount
        }

        func copyValue() -> SeasonalTransferGroup {
            return SeasonalTransferGroup(
                code: code,
                title: title,
                encounterID: encounterID,
                discount: discount,
                tags: tags,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a seasonal transfer group in status new.
    static func newSeasonalTransferGroup(_ code: String, title: String) -> SeasonalTransferGroup {
        return SeasonalTransferGroup(
            code: code,
            title: title,
            encounterID: "",
            discount: 0.0,
            tags: [],
            contactEmail: "",
            status: SeasonalTransferGroupStatus.new
        )
    }
}
