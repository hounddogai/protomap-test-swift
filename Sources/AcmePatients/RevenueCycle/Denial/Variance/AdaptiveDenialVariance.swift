import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a adaptive denial variance is in its life cycle.
    enum AdaptiveDenialVarianceStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A adaptive denial variance. Its code is unique within a tenant.
    final class AdaptiveDenialVariance {
        var code: String
        var label: String
        var score: Double
        var acuity: Int
        var approved: Bool
        var retries: Int
        var description: String
        var facility: String
        var budget: Double
        var archived: Bool
        var status: AdaptiveDenialVarianceStatus

        init(code: String, label: String, score: Double, acuity: Int, approved: Bool, retries: Int, description: String, facility: String, budget: Double, archived: Bool, status: AdaptiveDenialVarianceStatus) {
            self.code = code
            self.label = label
            self.score = score
            self.acuity = acuity
            self.approved = approved
            self.retries = retries
            self.description = description
            self.facility = facility
            self.budget = budget
            self.archived = archived
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

        func canMoveTo(_ next: AdaptiveDenialVarianceStatus) -> Bool {
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
                return next == AdaptiveDenialVarianceStatus.done || next == AdaptiveDenialVarianceStatus.failed
            case .running:
                return next == AdaptiveDenialVarianceStatus.failed
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

        func moveTo(_ next: AdaptiveDenialVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive denial variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func adjustedExposure() -> Double {
            return (score * budget * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveDenialVariance {
            return AdaptiveDenialVariance(
                code: code,
                label: label,
                score: score,
                acuity: acuity,
                approved: approved,
                retries: retries,
                description: description,
                facility: facility,
                budget: budget,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a adaptive denial variance in status new.
    static func newAdaptiveDenialVariance(_ code: String, label: String) -> AdaptiveDenialVariance {
        return AdaptiveDenialVariance(
            code: code,
            label: label,
            score: 0.0,
            acuity: 0,
            approved: false,
            retries: 0,
            description: "",
            facility: "",
            budget: 0.0,
            archived: false,
            status: AdaptiveDenialVarianceStatus.new
        )
    }
}
