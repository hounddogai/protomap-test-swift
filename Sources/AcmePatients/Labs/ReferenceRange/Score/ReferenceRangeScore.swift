import AcmePlatform
import Foundation

extension Labs {
    /// Where a reference range score is in its life cycle.
    enum ReferenceRangeScoreStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A reference range score as the reference range team keeps it.
    final class ReferenceRangeScore {
        var code: String
        var label: String
        var contactEmail: String
        var region: String
        var ratio: Double
        var version: Int
        var phone: String
        var status: ReferenceRangeScoreStatus

        init(code: String, label: String, contactEmail: String, region: String, ratio: Double, version: Int, phone: String, status: ReferenceRangeScoreStatus) {
            self.code = code
            self.label = label
            self.contactEmail = contactEmail
            self.region = region
            self.ratio = ratio
            self.version = version
            self.phone = phone
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ReferenceRangeScoreStatus) -> Bool {
            switch status {
            case .planned:
                return next == ReferenceRangeScoreStatus.completed
            case .scheduled:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == ReferenceRangeScoreStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReferenceRangeScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("reference range score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\("reference range score") \(code)"
        }

        func projectedValue() -> Double {
            return ((Double(version) + ratio) * 100).rounded() / 100
        }

        func copyValue() -> ReferenceRangeScore {
            return ReferenceRangeScore(
                code: code,
                label: label,
                contactEmail: contactEmail,
                region: region,
                ratio: ratio,
                version: version,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a reference range score in status planned.
    static func newReferenceRangeScore(_ code: String, label: String) -> ReferenceRangeScore {
        return ReferenceRangeScore(
            code: code,
            label: label,
            contactEmail: "",
            region: "",
            ratio: 0.0,
            version: 0,
            phone: "",
            status: ReferenceRangeScoreStatus.planned
        )
    }
}
