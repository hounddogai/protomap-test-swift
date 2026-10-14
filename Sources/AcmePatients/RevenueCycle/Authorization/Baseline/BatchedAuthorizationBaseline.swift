import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a batched authorization baseline is in its life cycle.
    enum BatchedAuthorizationBaselineStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A batched authorization baseline. Its code is unique within a tenant.
    final class BatchedAuthorizationBaseline {
        var code: String
        var name: String
        var startsAt: Int
        var ward: String
        var label: String
        var checksum: String
        var margin: Double
        var durationMinutes: Int
        var expiresAt: Int
        var batchSize: Int
        var score: Double
        var status: BatchedAuthorizationBaselineStatus

        init(code: String, name: String, startsAt: Int, ward: String, label: String, checksum: String, margin: Double, durationMinutes: Int, expiresAt: Int, batchSize: Int, score: Double, status: BatchedAuthorizationBaselineStatus) {
            self.code = code
            self.name = name
            self.startsAt = startsAt
            self.ward = ward
            self.label = label
            self.checksum = checksum
            self.margin = margin
            self.durationMinutes = durationMinutes
            self.expiresAt = expiresAt
            self.batchSize = batchSize
            self.score = score
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

        func canMoveTo(_ next: BatchedAuthorizationBaselineStatus) -> Bool {
            switch status {
            case .`open`:
                return next == BatchedAuthorizationBaselineStatus.archived
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == BatchedAuthorizationBaselineStatus.archived
            case .reopened:
                return next == BatchedAuthorizationBaselineStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedAuthorizationBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched authorization baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("batched authorization baseline") \(code)"
        }

        func effectiveTotal() -> Double {
            return ((Double(expiresAt) + margin) * 100).rounded() / 100
        }

        func copyValue() -> BatchedAuthorizationBaseline {
            return BatchedAuthorizationBaseline(
                code: code,
                name: name,
                startsAt: startsAt,
                ward: ward,
                label: label,
                checksum: checksum,
                margin: margin,
                durationMinutes: durationMinutes,
                expiresAt: expiresAt,
                batchSize: batchSize,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a batched authorization baseline in status open.
    static func newBatchedAuthorizationBaseline(_ code: String, name: String) -> BatchedAuthorizationBaseline {
        return BatchedAuthorizationBaseline(
            code: code,
            name: name,
            startsAt: 0,
            ward: "",
            label: "",
            checksum: "",
            margin: 0.0,
            durationMinutes: 0,
            expiresAt: 0,
            batchSize: 0,
            score: 0.0,
            status: BatchedAuthorizationBaselineStatus.`open`
        )
    }
}
