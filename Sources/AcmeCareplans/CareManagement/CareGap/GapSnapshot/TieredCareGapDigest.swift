import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a tiered care gap digest is in its life cycle.
    enum TieredCareGapDigestStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One tiered care gap digest, with what the planners need to act on it.
    final class TieredCareGapDigest {
        var code: String
        var name: String
        var archived: Bool
        var payer: String
        var acuity: Int
        var summary: String
        var specialty: String
        var unit: String
        var graceDays: Int
        var limit: Int
        var endsAt: Int
        var status: TieredCareGapDigestStatus

        init(code: String, name: String, archived: Bool, payer: String, acuity: Int, summary: String, specialty: String, unit: String, graceDays: Int, limit: Int, endsAt: Int, status: TieredCareGapDigestStatus) {
            self.code = code
            self.name = name
            self.archived = archived
            self.payer = payer
            self.acuity = acuity
            self.summary = summary
            self.specialty = specialty
            self.unit = unit
            self.graceDays = graceDays
            self.limit = limit
            self.endsAt = endsAt
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

        func canMoveTo(_ next: TieredCareGapDigestStatus) -> Bool {
            switch status {
            case .planned:
                return next == TieredCareGapDigestStatus.inProgress
            case .scheduled:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == TieredCareGapDigestStatus.completed
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: TieredCareGapDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered care gap digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func weightedExposure() -> Double {
            return (Double(limit) * Double(acuity) * 100).rounded() / 100
        }

        func copyValue() -> TieredCareGapDigest {
            return TieredCareGapDigest(
                code: code,
                name: name,
                archived: archived,
                payer: payer,
                acuity: acuity,
                summary: summary,
                specialty: specialty,
                unit: unit,
                graceDays: graceDays,
                limit: limit,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a tiered care gap digest in status planned.
    static func newTieredCareGapDigest(_ code: String, name: String) -> TieredCareGapDigest {
        return TieredCareGapDigest(
            code: code,
            name: name,
            archived: false,
            payer: "",
            acuity: 0,
            summary: "",
            specialty: "",
            unit: "",
            graceDays: 0,
            limit: 0,
            endsAt: 0,
            status: TieredCareGapDigestStatus.planned
        )
    }
}
