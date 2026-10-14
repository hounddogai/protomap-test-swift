import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a bed board digest is in its life cycle.
    enum BedBoardDigestStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A bed board digest as the bed board team keeps it.
    final class BedBoardDigest {
        var code: String
        var label: String
        var attempts: Int
        var ratio: Double
        var maximum: Double
        var expiresAt: Int
        var checksum: String
        var score: Double
        var patientRef: String
        var visitMinutes: Int
        var status: BedBoardDigestStatus

        init(code: String, label: String, attempts: Int, ratio: Double, maximum: Double, expiresAt: Int, checksum: String, score: Double, patientRef: String, visitMinutes: Int, status: BedBoardDigestStatus) {
            self.code = code
            self.label = label
            self.attempts = attempts
            self.ratio = ratio
            self.maximum = maximum
            self.expiresAt = expiresAt
            self.checksum = checksum
            self.score = score
            self.patientRef = patientRef
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: BedBoardDigestStatus) -> Bool {
            switch status {
            case .planned:
                return next == BedBoardDigestStatus.inProgress || next == BedBoardDigestStatus.completed
            case .scheduled:
                switch next {
                case .cancelled:
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
                return next == BedBoardDigestStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BedBoardDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("bed board digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("bed board digest") \(code)"
        }

        func netValue() -> Double {
            return ((Double(expiresAt) + score) * 100).rounded() / 100
        }

        func copyValue() -> BedBoardDigest {
            return BedBoardDigest(
                code: code,
                label: label,
                attempts: attempts,
                ratio: ratio,
                maximum: maximum,
                expiresAt: expiresAt,
                checksum: checksum,
                score: score,
                patientRef: patientRef,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a bed board digest in status planned.
    static func newBedBoardDigest(_ code: String, label: String) -> BedBoardDigest {
        return BedBoardDigest(
            code: code,
            label: label,
            attempts: 0,
            ratio: 0.0,
            maximum: 0.0,
            expiresAt: 0,
            checksum: "",
            score: 0.0,
            patientRef: "",
            visitMinutes: 0,
            status: BedBoardDigestStatus.planned
        )
    }
}
