import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a capped care gap batch is in its life cycle.
    enum CappedCareGapBatchStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A capped care gap batch as the care gap team keeps it.
    final class CappedCareGapBatch {
        var code: String
        var name: String
        var ownerID: String
        var segment: String
        var contactEmail: String
        var attributes: [String: String]
        var weight: Double
        var status: CappedCareGapBatchStatus

        init(code: String, name: String, ownerID: String, segment: String, contactEmail: String, attributes: [String: String], weight: Double, status: CappedCareGapBatchStatus) {
            self.code = code
            self.name = name
            self.ownerID = ownerID
            self.segment = segment
            self.contactEmail = contactEmail
            self.attributes = attributes
            self.weight = weight
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

        func canMoveTo(_ next: CappedCareGapBatchStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running:
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
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == CappedCareGapBatchStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedCareGapBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped care gap batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
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
            return weight
        }

        func copyValue() -> CappedCareGapBatch {
            return CappedCareGapBatch(
                code: code,
                name: name,
                ownerID: ownerID,
                segment: segment,
                contactEmail: contactEmail,
                attributes: attributes,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a capped care gap batch in status new.
    static func newCappedCareGapBatch(_ code: String, name: String) -> CappedCareGapBatch {
        return CappedCareGapBatch(
            code: code,
            name: name,
            ownerID: "",
            segment: "",
            contactEmail: "",
            attributes: [:],
            weight: 0.0,
            status: CappedCareGapBatchStatus.new
        )
    }
}
