import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a adaptive dispense proposal is in its life cycle.
    enum AdaptiveDispenseProposalStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A adaptive dispense proposal as the dispense team keeps it.
    final class AdaptiveDispenseProposal {
        var code: String
        var title: String
        var archived: Bool
        var endsAt: Int
        var threshold: Double
        var limit: Int
        var status: AdaptiveDispenseProposalStatus

        init(code: String, title: String, archived: Bool, endsAt: Int, threshold: Double, limit: Int, status: AdaptiveDispenseProposalStatus) {
            self.code = code
            self.title = title
            self.archived = archived
            self.endsAt = endsAt
            self.threshold = threshold
            self.limit = limit
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

        func canMoveTo(_ next: AdaptiveDispenseProposalStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .failed:
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

        func moveTo(_ next: AdaptiveDispenseProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive dispense proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func effectiveTotal() -> Double {
            return ((threshold + Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveDispenseProposal {
            return AdaptiveDispenseProposal(
                code: code,
                title: title,
                archived: archived,
                endsAt: endsAt,
                threshold: threshold,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a adaptive dispense proposal in status new.
    static func newAdaptiveDispenseProposal(_ code: String, title: String) -> AdaptiveDispenseProposal {
        return AdaptiveDispenseProposal(
            code: code,
            title: title,
            archived: false,
            endsAt: 0,
            threshold: 0.0,
            limit: 0,
            status: AdaptiveDispenseProposalStatus.new
        )
    }
}
