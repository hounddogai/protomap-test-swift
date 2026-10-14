import AcmePlatform
import Foundation

extension Imaging {
    /// Where a worklist digest is in its life cycle.
    enum WorklistDigestStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A worklist digest as the worklist team keeps it.
    final class WorklistDigest {
        var code: String
        var title: String
        var endsAt: Int
        var retries: Int
        var threshold: Double
        var specialty: String
        var ceiling: Double
        var status: WorklistDigestStatus

        init(code: String, title: String, endsAt: Int, retries: Int, threshold: Double, specialty: String, ceiling: Double, status: WorklistDigestStatus) {
            self.code = code
            self.title = title
            self.endsAt = endsAt
            self.retries = retries
            self.threshold = threshold
            self.specialty = specialty
            self.ceiling = ceiling
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WorklistDigestStatus) -> Bool {
            switch status {
            case .created:
                return next == WorklistDigestStatus.validated || next == WorklistDigestStatus.retired
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: WorklistDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("worklist digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("worklist digest") \(code)"
        }

        func netVolume() -> Double {
            return ((threshold + ceiling) * 100).rounded() / 100
        }

        func copyValue() -> WorklistDigest {
            return WorklistDigest(
                code: code,
                title: title,
                endsAt: endsAt,
                retries: retries,
                threshold: threshold,
                specialty: specialty,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a worklist digest in status created.
    static func newWorklistDigest(_ code: String, title: String) -> WorklistDigest {
        return WorklistDigest(
            code: code,
            title: title,
            endsAt: 0,
            retries: 0,
            threshold: 0.0,
            specialty: "",
            ceiling: 0.0,
            status: WorklistDigestStatus.created
        )
    }
}
