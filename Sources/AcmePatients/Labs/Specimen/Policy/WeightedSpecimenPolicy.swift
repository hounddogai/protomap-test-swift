import AcmePlatform
import Foundation

extension Labs {
    /// Where a weighted specimen policy is in its life cycle.
    enum WeightedSpecimenPolicyStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A weighted specimen policy as the specimen team keeps it.
    final class WeightedSpecimenPolicy {
        var code: String
        var label: String
        var pinned: Bool
        var createdAt: Int
        var sequence: Int
        var status: WeightedSpecimenPolicyStatus

        init(code: String, label: String, pinned: Bool, createdAt: Int, sequence: Int, status: WeightedSpecimenPolicyStatus) {
            self.code = code
            self.label = label
            self.pinned = pinned
            self.createdAt = createdAt
            self.sequence = sequence
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

        func canMoveTo(_ next: WeightedSpecimenPolicyStatus) -> Bool {
            switch status {
            case .`open`:
                return next == WeightedSpecimenPolicyStatus.reopened
            case .inReview:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == WeightedSpecimenPolicyStatus.reopened || next == WeightedSpecimenPolicyStatus.archived
            case .reopened:
                return next == WeightedSpecimenPolicyStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedSpecimenPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted specimen policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func adjustedVolume() -> Double {
            return ((Double(sequence) + Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> WeightedSpecimenPolicy {
            return WeightedSpecimenPolicy(
                code: code,
                label: label,
                pinned: pinned,
                createdAt: createdAt,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a weighted specimen policy in status open.
    static func newWeightedSpecimenPolicy(_ code: String, label: String) -> WeightedSpecimenPolicy {
        return WeightedSpecimenPolicy(
            code: code,
            label: label,
            pinned: false,
            createdAt: 0,
            sequence: 0,
            status: WeightedSpecimenPolicyStatus.`open`
        )
    }
}
