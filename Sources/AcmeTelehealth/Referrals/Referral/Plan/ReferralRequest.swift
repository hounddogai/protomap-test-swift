import AcmePlatform
import Foundation

extension Referrals {
    /// Where a referral request is in its life cycle.
    enum ReferralRequestStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A referral request. Its code is unique within a tenant.
    final class ReferralRequest {
        var code: String
        var name: String
        var acuity: Int
        var score: Double
        var bed: String
        var threshold: Double
        var title: String
        var ratio: Double
        var sequence: Int
        var weight: Double
        var expiresAt: Int
        var status: ReferralRequestStatus

        init(code: String, name: String, acuity: Int, score: Double, bed: String, threshold: Double, title: String, ratio: Double, sequence: Int, weight: Double, expiresAt: Int, status: ReferralRequestStatus) {
            self.code = code
            self.name = name
            self.acuity = acuity
            self.score = score
            self.bed = bed
            self.threshold = threshold
            self.title = title
            self.ratio = ratio
            self.sequence = sequence
            self.weight = weight
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: ReferralRequestStatus) -> Bool {
            switch status {
            case .idle:
                return next == ReferralRequestStatus.warming
            case .warming:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == ReferralRequestStatus.draining || next == ReferralRequestStatus.stopped
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

        func moveTo(_ next: ReferralRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("referral request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("referral request") \(code)"
        }

        func weightedLoad() -> Double {
            return ((threshold - ratio) * 100).rounded() / 100
        }

        func copyValue() -> ReferralRequest {
            return ReferralRequest(
                code: code,
                name: name,
                acuity: acuity,
                score: score,
                bed: bed,
                threshold: threshold,
                title: title,
                ratio: ratio,
                sequence: sequence,
                weight: weight,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a referral request in status idle.
    static func newReferralRequest(_ code: String, name: String) -> ReferralRequest {
        return ReferralRequest(
            code: code,
            name: name,
            acuity: 0,
            score: 0.0,
            bed: "",
            threshold: 0.0,
            title: "",
            ratio: 0.0,
            sequence: 0,
            weight: 0.0,
            expiresAt: 0,
            status: ReferralRequestStatus.idle
        )
    }
}
