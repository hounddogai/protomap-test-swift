import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a primary recall digest is in its life cycle.
    enum PrimaryRecallDigestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One primary recall digest, with what the planners need to act on it.
    final class PrimaryRecallDigest {
        var code: String
        var name: String
        var phone: String
        var minimum: Double
        var sequence: Int
        var reviewer: String
        var patientRef: String
        var timezone: String
        var ratio: Double
        var status: PrimaryRecallDigestStatus

        init(code: String, name: String, phone: String, minimum: Double, sequence: Int, reviewer: String, patientRef: String, timezone: String, ratio: Double, status: PrimaryRecallDigestStatus) {
            self.code = code
            self.name = name
            self.phone = phone
            self.minimum = minimum
            self.sequence = sequence
            self.reviewer = reviewer
            self.patientRef = patientRef
            self.timezone = timezone
            self.ratio = ratio
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

        func canMoveTo(_ next: PrimaryRecallDigestStatus) -> Bool {
            switch status {
            case .draft:
                return next == PrimaryRecallDigestStatus.pending
            case .pending:
                return next == PrimaryRecallDigestStatus.suspended || next == PrimaryRecallDigestStatus.closed
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: PrimaryRecallDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary recall digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("primary recall digest") \(code)"
        }

        func projectedTotal() -> Double {
            return (Double(sequence) * ratio * 100).rounded() / 100
        }

        func copyValue() -> PrimaryRecallDigest {
            return PrimaryRecallDigest(
                code: code,
                name: name,
                phone: phone,
                minimum: minimum,
                sequence: sequence,
                reviewer: reviewer,
                patientRef: patientRef,
                timezone: timezone,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a primary recall digest in status draft.
    static func newPrimaryRecallDigest(_ code: String, name: String) -> PrimaryRecallDigest {
        return PrimaryRecallDigest(
            code: code,
            name: name,
            phone: "",
            minimum: 0.0,
            sequence: 0,
            reviewer: "",
            patientRef: "",
            timezone: "",
            ratio: 0.0,
            status: PrimaryRecallDigestStatus.draft
        )
    }
}
