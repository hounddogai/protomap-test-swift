import AcmePlatform
import Foundation

extension Imaging {
    /// Where a worklist policy is in its life cycle.
    enum WorklistPolicyStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One worklist policy, with what the planners need to act on it.
    final class WorklistPolicy {
        var code: String
        var name: String
        var bed: String
        var region: String
        var timezone: String
        var payer: String
        var threshold: Double
        var startsAt: Int
        var status: WorklistPolicyStatus

        init(code: String, name: String, bed: String, region: String, timezone: String, payer: String, threshold: Double, startsAt: Int, status: WorklistPolicyStatus) {
            self.code = code
            self.name = name
            self.bed = bed
            self.region = region
            self.timezone = timezone
            self.payer = payer
            self.threshold = threshold
            self.startsAt = startsAt
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

        func canMoveTo(_ next: WorklistPolicyStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .failed:
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

        func moveTo(_ next: WorklistPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("worklist policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func effectiveExposure() -> Double {
            return ((Double(startsAt) - threshold) * 100).rounded() / 100
        }

        func copyValue() -> WorklistPolicy {
            return WorklistPolicy(
                code: code,
                name: name,
                bed: bed,
                region: region,
                timezone: timezone,
                payer: payer,
                threshold: threshold,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a worklist policy in status new.
    static func newWorklistPolicy(_ code: String, name: String) -> WorklistPolicy {
        return WorklistPolicy(
            code: code,
            name: name,
            bed: "",
            region: "",
            timezone: "",
            payer: "",
            threshold: 0.0,
            startsAt: 0,
            status: WorklistPolicyStatus.new
        )
    }
}
