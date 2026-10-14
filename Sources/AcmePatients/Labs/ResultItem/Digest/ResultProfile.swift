import AcmePlatform
import Foundation

extension Labs {
    /// Where a result profile is in its life cycle.
    enum ResultProfileStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One result profile, with what the planners need to act on it.
    final class ResultProfile {
        var code: String
        var label: String
        var retries: Int
        var procedureCode: String
        var endsAt: Int
        var channel: String
        var patientRef: String
        var version: Int
        var floorValue: Double
        var status: ResultProfileStatus

        init(code: String, label: String, retries: Int, procedureCode: String, endsAt: Int, channel: String, patientRef: String, version: Int, floorValue: Double, status: ResultProfileStatus) {
            self.code = code
            self.label = label
            self.retries = retries
            self.procedureCode = procedureCode
            self.endsAt = endsAt
            self.channel = channel
            self.patientRef = patientRef
            self.version = version
            self.floorValue = floorValue
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

        func canMoveTo(_ next: ResultProfileStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == ResultProfileStatus.reopened || next == ResultProfileStatus.archived
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

        func moveTo(_ next: ResultProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("result profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func displayLabel() -> String {
            return "\("result profile") \(code)"
        }

        func netValue() -> Double {
            return ((Double(version) - Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> ResultProfile {
            return ResultProfile(
                code: code,
                label: label,
                retries: retries,
                procedureCode: procedureCode,
                endsAt: endsAt,
                channel: channel,
                patientRef: patientRef,
                version: version,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a result profile in status open.
    static func newResultProfile(_ code: String, label: String) -> ResultProfile {
        return ResultProfile(
            code: code,
            label: label,
            retries: 0,
            procedureCode: "",
            endsAt: 0,
            channel: "",
            patientRef: "",
            version: 0,
            floorValue: 0.0,
            status: ResultProfileStatus.`open`
        )
    }
}
