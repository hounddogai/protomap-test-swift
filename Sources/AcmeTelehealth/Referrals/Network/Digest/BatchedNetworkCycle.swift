import AcmePlatform
import Foundation

extension Referrals {
    /// Where a batched network cycle is in its life cycle.
    enum BatchedNetworkCycleStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One batched network cycle, with what the planners need to act on it.
    final class BatchedNetworkCycle {
        var code: String
        var label: String
        var attributes: [String: String]
        var patientRef: String
        var source: String
        var category: String
        var pinned: Bool
        var region: String
        var amount: Double
        var status: BatchedNetworkCycleStatus

        init(code: String, label: String, attributes: [String: String], patientRef: String, source: String, category: String, pinned: Bool, region: String, amount: Double, status: BatchedNetworkCycleStatus) {
            self.code = code
            self.label = label
            self.attributes = attributes
            self.patientRef = patientRef
            self.source = source
            self.category = category
            self.pinned = pinned
            self.region = region
            self.amount = amount
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BatchedNetworkCycleStatus) -> Bool {
            switch status {
            case .created:
                return next == BatchedNetworkCycleStatus.validated
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == BatchedNetworkCycleStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedNetworkCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched network cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
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

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> BatchedNetworkCycle {
            return BatchedNetworkCycle(
                code: code,
                label: label,
                attributes: attributes,
                patientRef: patientRef,
                source: source,
                category: category,
                pinned: pinned,
                region: region,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a batched network cycle in status created.
    static func newBatchedNetworkCycle(_ code: String, label: String) -> BatchedNetworkCycle {
        return BatchedNetworkCycle(
            code: code,
            label: label,
            attributes: [:],
            patientRef: "",
            source: "",
            category: "",
            pinned: false,
            region: "",
            amount: 0.0,
            status: BatchedNetworkCycleStatus.created
        )
    }
}
