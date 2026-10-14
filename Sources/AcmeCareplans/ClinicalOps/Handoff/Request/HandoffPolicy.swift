import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a handoff policy is in its life cycle.
    enum HandoffPolicyStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A handoff policy as the handoff team keeps it.
    final class HandoffPolicy {
        var code: String
        var title: String
        var procedureCode: String
        var attributes: [String: String]
        var label: String
        var source: String
        var score: Double
        var ratio: Double
        var pinned: Bool
        var sequence: Int
        var active: Bool
        var status: HandoffPolicyStatus

        init(code: String, title: String, procedureCode: String, attributes: [String: String], label: String, source: String, score: Double, ratio: Double, pinned: Bool, sequence: Int, active: Bool, status: HandoffPolicyStatus) {
            self.code = code
            self.title = title
            self.procedureCode = procedureCode
            self.attributes = attributes
            self.label = label
            self.source = source
            self.score = score
            self.ratio = ratio
            self.pinned = pinned
            self.sequence = sequence
            self.active = active
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

        func canMoveTo(_ next: HandoffPolicyStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == HandoffPolicyStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: HandoffPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("handoff policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("handoff policy") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func adjustedValue() -> Double {
            return ((ratio - Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> HandoffPolicy {
            return HandoffPolicy(
                code: code,
                title: title,
                procedureCode: procedureCode,
                attributes: attributes,
                label: label,
                source: source,
                score: score,
                ratio: ratio,
                pinned: pinned,
                sequence: sequence,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a handoff policy in status idle.
    static func newHandoffPolicy(_ code: String, title: String) -> HandoffPolicy {
        return HandoffPolicy(
            code: code,
            title: title,
            procedureCode: "",
            attributes: [:],
            label: "",
            source: "",
            score: 0.0,
            ratio: 0.0,
            pinned: false,
            sequence: 0,
            active: false,
            status: HandoffPolicyStatus.idle
        )
    }
}
