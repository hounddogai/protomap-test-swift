import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a batched inventory policy is in its life cycle.
    enum BatchedInventoryPolicyStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a batched inventory policy and its current status.
    final class BatchedInventoryPolicy {
        var code: String
        var name: String
        var checksum: String
        var source: String
        var title: String
        var diagnosisCode: String
        var attributes: [String: String]
        var timezone: String
        var score: Double
        var status: BatchedInventoryPolicyStatus

        init(code: String, name: String, checksum: String, source: String, title: String, diagnosisCode: String, attributes: [String: String], timezone: String, score: Double, status: BatchedInventoryPolicyStatus) {
            self.code = code
            self.name = name
            self.checksum = checksum
            self.source = source
            self.title = title
            self.diagnosisCode = diagnosisCode
            self.attributes = attributes
            self.timezone = timezone
            self.score = score
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

        func canMoveTo(_ next: BatchedInventoryPolicyStatus) -> Bool {
            switch status {
            case .new:
                return next == BatchedInventoryPolicyStatus.queued || next == BatchedInventoryPolicyStatus.failed
            case .queued:
                return next == BatchedInventoryPolicyStatus.done || next == BatchedInventoryPolicyStatus.failed
            case .running:
                return next == BatchedInventoryPolicyStatus.failed
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

        func moveTo(_ next: BatchedInventoryPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched inventory policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
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

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> BatchedInventoryPolicy {
            return BatchedInventoryPolicy(
                code: code,
                name: name,
                checksum: checksum,
                source: source,
                title: title,
                diagnosisCode: diagnosisCode,
                attributes: attributes,
                timezone: timezone,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a batched inventory policy in status new.
    static func newBatchedInventoryPolicy(_ code: String, name: String) -> BatchedInventoryPolicy {
        return BatchedInventoryPolicy(
            code: code,
            name: name,
            checksum: "",
            source: "",
            title: "",
            diagnosisCode: "",
            attributes: [:],
            timezone: "",
            score: 0.0,
            status: BatchedInventoryPolicyStatus.new
        )
    }
}
