import AcmePlatform
import Foundation

extension Referrals {
    /// Where a batched referral draft is in its life cycle.
    enum BatchedReferralDraftStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a batched referral draft and its current status.
    final class BatchedReferralDraft {
        var code: String
        var name: String
        var label: String
        var sequence: Int
        var title: String
        var source: String
        var batchSize: Int
        var copay: Double
        var locale: String
        var revision: Int
        var reviewer: String
        var status: BatchedReferralDraftStatus

        init(code: String, name: String, label: String, sequence: Int, title: String, source: String, batchSize: Int, copay: Double, locale: String, revision: Int, reviewer: String, status: BatchedReferralDraftStatus) {
            self.code = code
            self.name = name
            self.label = label
            self.sequence = sequence
            self.title = title
            self.source = source
            self.batchSize = batchSize
            self.copay = copay
            self.locale = locale
            self.revision = revision
            self.reviewer = reviewer
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BatchedReferralDraftStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == BatchedReferralDraftStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedReferralDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched referral draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\("batched referral draft") \(code)"
        }

        func effectiveExposure() -> Double {
            return ((Double(revision) - copay) * 100).rounded() / 100
        }

        func copyValue() -> BatchedReferralDraft {
            return BatchedReferralDraft(
                code: code,
                name: name,
                label: label,
                sequence: sequence,
                title: title,
                source: source,
                batchSize: batchSize,
                copay: copay,
                locale: locale,
                revision: revision,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a batched referral draft in status proposed.
    static func newBatchedReferralDraft(_ code: String, name: String) -> BatchedReferralDraft {
        return BatchedReferralDraft(
            code: code,
            name: name,
            label: "",
            sequence: 0,
            title: "",
            source: "",
            batchSize: 0,
            copay: 0.0,
            locale: "",
            revision: 0,
            reviewer: "",
            status: BatchedReferralDraftStatus.proposed
        )
    }
}
