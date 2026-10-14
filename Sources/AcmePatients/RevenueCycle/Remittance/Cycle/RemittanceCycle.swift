import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a remittance cycle is in its life cycle.
    enum RemittanceCycleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One remittance cycle, with what the planners need to act on it.
    final class RemittanceCycle {
        var code: String
        var name: String
        var phone: String
        var contactEmail: String
        var score: Double
        var copay: Double
        var externalRef: String
        var amount: Double
        var sequence: Int
        var archived: Bool
        var attributes: [String: String]
        var status: RemittanceCycleStatus

        init(code: String, name: String, phone: String, contactEmail: String, score: Double, copay: Double, externalRef: String, amount: Double, sequence: Int, archived: Bool, attributes: [String: String], status: RemittanceCycleStatus) {
            self.code = code
            self.name = name
            self.phone = phone
            self.contactEmail = contactEmail
            self.score = score
            self.copay = copay
            self.externalRef = externalRef
            self.amount = amount
            self.sequence = sequence
            self.archived = archived
            self.attributes = attributes
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

        func canMoveTo(_ next: RemittanceCycleStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == RemittanceCycleStatus.stopped
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == RemittanceCycleStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RemittanceCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("remittance cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
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

        func effectiveExposure() -> Double {
            return ((Double(sequence) - amount) * 100).rounded() / 100
        }

        func copyValue() -> RemittanceCycle {
            return RemittanceCycle(
                code: code,
                name: name,
                phone: phone,
                contactEmail: contactEmail,
                score: score,
                copay: copay,
                externalRef: externalRef,
                amount: amount,
                sequence: sequence,
                archived: archived,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a remittance cycle in status idle.
    static func newRemittanceCycle(_ code: String, name: String) -> RemittanceCycle {
        return RemittanceCycle(
            code: code,
            name: name,
            phone: "",
            contactEmail: "",
            score: 0.0,
            copay: 0.0,
            externalRef: "",
            amount: 0.0,
            sequence: 0,
            archived: false,
            attributes: [:],
            status: RemittanceCycleStatus.idle
        )
    }
}
