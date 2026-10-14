import AcmePlatform
import Foundation

extension Imaging {
    /// Where a scheduled care protocol exception is in its life cycle.
    enum ScheduledCareProtocolExceptionStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a scheduled care protocol exception and its current status.
    final class ScheduledCareProtocolException {
        var code: String
        var title: String
        var encounterID: String
        var sequence: Int
        var region: String
        var channel: String
        var priority: Int
        var checksum: String
        var allergy: String
        var bed: String
        var status: ScheduledCareProtocolExceptionStatus

        init(code: String, title: String, encounterID: String, sequence: Int, region: String, channel: String, priority: Int, checksum: String, allergy: String, bed: String, status: ScheduledCareProtocolExceptionStatus) {
            self.code = code
            self.title = title
            self.encounterID = encounterID
            self.sequence = sequence
            self.region = region
            self.channel = channel
            self.priority = priority
            self.checksum = checksum
            self.allergy = allergy
            self.bed = bed
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

        func canMoveTo(_ next: ScheduledCareProtocolExceptionStatus) -> Bool {
            switch status {
            case .`open`:
                return next == ScheduledCareProtocolExceptionStatus.archived
            case .inReview:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: ScheduledCareProtocolExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled care protocol exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("scheduled care protocol exception") \(code)"
        }

        func projectedVolume() -> Double {
            return (Double(sequence) * Double(priority) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledCareProtocolException {
            return ScheduledCareProtocolException(
                code: code,
                title: title,
                encounterID: encounterID,
                sequence: sequence,
                region: region,
                channel: channel,
                priority: priority,
                checksum: checksum,
                allergy: allergy,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a scheduled care protocol exception in status open.
    static func newScheduledCareProtocolException(_ code: String, title: String) -> ScheduledCareProtocolException {
        return ScheduledCareProtocolException(
            code: code,
            title: title,
            encounterID: "",
            sequence: 0,
            region: "",
            channel: "",
            priority: 0,
            checksum: "",
            allergy: "",
            bed: "",
            status: ScheduledCareProtocolExceptionStatus.`open`
        )
    }
}
