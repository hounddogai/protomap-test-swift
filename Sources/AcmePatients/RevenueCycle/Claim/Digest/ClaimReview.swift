import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a claim review is in its life cycle.
    enum ClaimReviewStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A claim review as the claim team keeps it.
    final class ClaimReview {
        var code: String
        var name: String
        var budget: Double
        var margin: Double
        var minimum: Double
        var expiresAt: Int
        var visible: Bool
        var batchSize: Int
        var checksum: String
        var visitMinutes: Int
        var specialty: String
        var status: ClaimReviewStatus

        init(code: String, name: String, budget: Double, margin: Double, minimum: Double, expiresAt: Int, visible: Bool, batchSize: Int, checksum: String, visitMinutes: Int, specialty: String, status: ClaimReviewStatus) {
            self.code = code
            self.name = name
            self.budget = budget
            self.margin = margin
            self.minimum = minimum
            self.expiresAt = expiresAt
            self.visible = visible
            self.batchSize = batchSize
            self.checksum = checksum
            self.visitMinutes = visitMinutes
            self.specialty = specialty
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ClaimReviewStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: ClaimReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("claim review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func netVolume() -> Double {
            return ((Double(visitMinutes) + Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> ClaimReview {
            return ClaimReview(
                code: code,
                name: name,
                budget: budget,
                margin: margin,
                minimum: minimum,
                expiresAt: expiresAt,
                visible: visible,
                batchSize: batchSize,
                checksum: checksum,
                visitMinutes: visitMinutes,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a claim review in status new.
    static func newClaimReview(_ code: String, name: String) -> ClaimReview {
        return ClaimReview(
            code: code,
            name: name,
            budget: 0.0,
            margin: 0.0,
            minimum: 0.0,
            expiresAt: 0,
            visible: false,
            batchSize: 0,
            checksum: "",
            visitMinutes: 0,
            specialty: "",
            status: ClaimReviewStatus.new
        )
    }
}
