import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a batched claim agreement is in its life cycle.
    enum BatchedClaimAgreementStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A batched claim agreement. Its code is unique within a tenant.
    final class BatchedClaimAgreement {
        var code: String
        var label: String
        var channel: String
        var attributes: [String: String]
        var quantity: Int
        var description: String
        var threshold: Double
        var category: String
        var weight: Double
        var ceiling: Double
        var rate: Double
        var status: BatchedClaimAgreementStatus

        init(code: String, label: String, channel: String, attributes: [String: String], quantity: Int, description: String, threshold: Double, category: String, weight: Double, ceiling: Double, rate: Double, status: BatchedClaimAgreementStatus) {
            self.code = code
            self.label = label
            self.channel = channel
            self.attributes = attributes
            self.quantity = quantity
            self.description = description
            self.threshold = threshold
            self.category = category
            self.weight = weight
            self.ceiling = ceiling
            self.rate = rate
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

        func canMoveTo(_ next: BatchedClaimAgreementStatus) -> Bool {
            switch status {
            case .proposed:
                return next == BatchedClaimAgreementStatus.approved || next == BatchedClaimAgreementStatus.withdrawn
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: BatchedClaimAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched claim agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
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

        func effectiveTotal() -> Double {
            return ((ceiling + rate) * 100).rounded() / 100
        }

        func copyValue() -> BatchedClaimAgreement {
            return BatchedClaimAgreement(
                code: code,
                label: label,
                channel: channel,
                attributes: attributes,
                quantity: quantity,
                description: description,
                threshold: threshold,
                category: category,
                weight: weight,
                ceiling: ceiling,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a batched claim agreement in status proposed.
    static func newBatchedClaimAgreement(_ code: String, label: String) -> BatchedClaimAgreement {
        return BatchedClaimAgreement(
            code: code,
            label: label,
            channel: "",
            attributes: [:],
            quantity: 0,
            description: "",
            threshold: 0.0,
            category: "",
            weight: 0.0,
            ceiling: 0.0,
            rate: 0.0,
            status: BatchedClaimAgreementStatus.proposed
        )
    }
}
