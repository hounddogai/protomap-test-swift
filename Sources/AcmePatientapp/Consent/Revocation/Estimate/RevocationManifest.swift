import AcmePlatform
import Foundation

extension Consent {
    /// Where a revocation manifest is in its life cycle.
    enum RevocationManifestStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One revocation manifest, with what the planners need to act on it.
    final class RevocationManifest {
        var code: String
        var title: String
        var phone: String
        var reviewer: String
        var pinned: Bool
        var patientRef: String
        var maximum: Double
        var segment: String
        var updatedAt: Int
        var status: RevocationManifestStatus

        init(code: String, title: String, phone: String, reviewer: String, pinned: Bool, patientRef: String, maximum: Double, segment: String, updatedAt: Int, status: RevocationManifestStatus) {
            self.code = code
            self.title = title
            self.phone = phone
            self.reviewer = reviewer
            self.pinned = pinned
            self.patientRef = patientRef
            self.maximum = maximum
            self.segment = segment
            self.updatedAt = updatedAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RevocationManifestStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == RevocationManifestStatus.ready
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == RevocationManifestStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RevocationManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("revocation manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("revocation manifest") \(code)"
        }

        func netValue() -> Double {
            return (maximum * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> RevocationManifest {
            return RevocationManifest(
                code: code,
                title: title,
                phone: phone,
                reviewer: reviewer,
                pinned: pinned,
                patientRef: patientRef,
                maximum: maximum,
                segment: segment,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a revocation manifest in status idle.
    static func newRevocationManifest(_ code: String, title: String) -> RevocationManifest {
        return RevocationManifest(
            code: code,
            title: title,
            phone: "",
            reviewer: "",
            pinned: false,
            patientRef: "",
            maximum: 0.0,
            segment: "",
            updatedAt: 0,
            status: RevocationManifestStatus.idle
        )
    }
}
