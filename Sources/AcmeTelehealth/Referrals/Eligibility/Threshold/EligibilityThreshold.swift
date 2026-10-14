import AcmePlatform
import Foundation

extension Referrals {
    /// Where a eligibility threshold is in its life cycle.
    enum EligibilityThresholdStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A eligibility threshold as the eligibility team keeps it.
    final class EligibilityThreshold {
        var code: String
        var label: String
        var allergy: String
        var externalRef: String
        var tags: [String]
        var threshold: Double
        var channel: String
        var revision: Int
        var segment: String
        var createdAt: Int
        var status: EligibilityThresholdStatus

        init(code: String, label: String, allergy: String, externalRef: String, tags: [String], threshold: Double, channel: String, revision: Int, segment: String, createdAt: Int, status: EligibilityThresholdStatus) {
            self.code = code
            self.label = label
            self.allergy = allergy
            self.externalRef = externalRef
            self.tags = tags
            self.threshold = threshold
            self.channel = channel
            self.revision = revision
            self.segment = segment
            self.createdAt = createdAt
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

        func canMoveTo(_ next: EligibilityThresholdStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == EligibilityThresholdStatus.ready
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: EligibilityThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("eligibility threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netLoad() -> Double {
            return ((Double(createdAt) + threshold) * 100).rounded() / 100
        }

        func copyValue() -> EligibilityThreshold {
            return EligibilityThreshold(
                code: code,
                label: label,
                allergy: allergy,
                externalRef: externalRef,
                tags: tags,
                threshold: threshold,
                channel: channel,
                revision: revision,
                segment: segment,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a eligibility threshold in status idle.
    static func newEligibilityThreshold(_ code: String, label: String) -> EligibilityThreshold {
        return EligibilityThreshold(
            code: code,
            label: label,
            allergy: "",
            externalRef: "",
            tags: [],
            threshold: 0.0,
            channel: "",
            revision: 0,
            segment: "",
            createdAt: 0,
            status: EligibilityThresholdStatus.idle
        )
    }
}
