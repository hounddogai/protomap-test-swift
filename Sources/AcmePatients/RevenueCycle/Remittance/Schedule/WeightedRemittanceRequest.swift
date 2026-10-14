import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a weighted remittance request is in its life cycle.
    enum WeightedRemittanceRequestStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One weighted remittance request, with what the planners need to act on it.
    final class WeightedRemittanceRequest {
        var code: String
        var label: String
        var score: Double
        var createdAt: Int
        var summary: String
        var expiresAt: Int
        var status: WeightedRemittanceRequestStatus

        init(code: String, label: String, score: Double, createdAt: Int, summary: String, expiresAt: Int, status: WeightedRemittanceRequestStatus) {
            self.code = code
            self.label = label
            self.score = score
            self.createdAt = createdAt
            self.summary = summary
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: WeightedRemittanceRequestStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == WeightedRemittanceRequestStatus.done || next == WeightedRemittanceRequestStatus.failed
            case .running:
                return next == WeightedRemittanceRequestStatus.done || next == WeightedRemittanceRequestStatus.failed
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

        func moveTo(_ next: WeightedRemittanceRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted remittance request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func projectedLoad() -> Double {
            return ((score + Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> WeightedRemittanceRequest {
            return WeightedRemittanceRequest(
                code: code,
                label: label,
                score: score,
                createdAt: createdAt,
                summary: summary,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a weighted remittance request in status new.
    static func newWeightedRemittanceRequest(_ code: String, label: String) -> WeightedRemittanceRequest {
        return WeightedRemittanceRequest(
            code: code,
            label: label,
            score: 0.0,
            createdAt: 0,
            summary: "",
            expiresAt: 0,
            status: WeightedRemittanceRequestStatus.new
        )
    }
}
