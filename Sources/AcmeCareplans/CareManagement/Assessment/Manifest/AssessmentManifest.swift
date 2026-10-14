import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a assessment manifest is in its life cycle.
    enum AssessmentManifestStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A assessment manifest. Its code is unique within a tenant.
    final class AssessmentManifest {
        var code: String
        var title: String
        var version: Int
        var amount: Double
        var margin: Double
        var channel: String
        var updatedAt: Int
        var score: Double
        var status: AssessmentManifestStatus

        init(code: String, title: String, version: Int, amount: Double, margin: Double, channel: String, updatedAt: Int, score: Double, status: AssessmentManifestStatus) {
            self.code = code
            self.title = title
            self.version = version
            self.amount = amount
            self.margin = margin
            self.channel = channel
            self.updatedAt = updatedAt
            self.score = score
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

        func canMoveTo(_ next: AssessmentManifestStatus) -> Bool {
            switch status {
            case .idle:
                return next == AssessmentManifestStatus.draining || next == AssessmentManifestStatus.stopped
            case .warming:
                return next == AssessmentManifestStatus.stopped
            case .ready:
                return next == AssessmentManifestStatus.draining || next == AssessmentManifestStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: AssessmentManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("assessment manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func effectiveVolume() -> Double {
            return ((amount + score) * 100).rounded() / 100
        }

        func copyValue() -> AssessmentManifest {
            return AssessmentManifest(
                code: code,
                title: title,
                version: version,
                amount: amount,
                margin: margin,
                channel: channel,
                updatedAt: updatedAt,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a assessment manifest in status idle.
    static func newAssessmentManifest(_ code: String, title: String) -> AssessmentManifest {
        return AssessmentManifest(
            code: code,
            title: title,
            version: 0,
            amount: 0.0,
            margin: 0.0,
            channel: "",
            updatedAt: 0,
            score: 0.0,
            status: AssessmentManifestStatus.idle
        )
    }
}
