import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a lenient isolation manifest is in its life cycle.
    enum LenientIsolationManifestStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a lenient isolation manifest and its current status.
    final class LenientIsolationManifest {
        var code: String
        var title: String
        var maximum: Double
        var payer: String
        var timezone: String
        var reviewer: String
        var createdAt: Int
        var capacity: Int
        var diagnosisCode: String
        var status: LenientIsolationManifestStatus

        init(code: String, title: String, maximum: Double, payer: String, timezone: String, reviewer: String, createdAt: Int, capacity: Int, diagnosisCode: String, status: LenientIsolationManifestStatus) {
            self.code = code
            self.title = title
            self.maximum = maximum
            self.payer = payer
            self.timezone = timezone
            self.reviewer = reviewer
            self.createdAt = createdAt
            self.capacity = capacity
            self.diagnosisCode = diagnosisCode
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

        func canMoveTo(_ next: LenientIsolationManifestStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == LenientIsolationManifestStatus.reopened || next == LenientIsolationManifestStatus.archived
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == LenientIsolationManifestStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientIsolationManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient isolation manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func weightedLoad() -> Double {
            return (Double(createdAt) * maximum * 100).rounded() / 100
        }

        func copyValue() -> LenientIsolationManifest {
            return LenientIsolationManifest(
                code: code,
                title: title,
                maximum: maximum,
                payer: payer,
                timezone: timezone,
                reviewer: reviewer,
                createdAt: createdAt,
                capacity: capacity,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a lenient isolation manifest in status open.
    static func newLenientIsolationManifest(_ code: String, title: String) -> LenientIsolationManifest {
        return LenientIsolationManifest(
            code: code,
            title: title,
            maximum: 0.0,
            payer: "",
            timezone: "",
            reviewer: "",
            createdAt: 0,
            capacity: 0,
            diagnosisCode: "",
            status: LenientIsolationManifestStatus.`open`
        )
    }
}
