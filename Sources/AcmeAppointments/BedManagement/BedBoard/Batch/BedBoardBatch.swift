import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a bed board batch is in its life cycle.
    enum BedBoardBatchStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A bed board batch. Its code is unique within a tenant.
    final class BedBoardBatch {
        var code: String
        var title: String
        var checksum: String
        var discount: Double
        var phone: String
        var acuity: Int
        var retries: Int
        var attempts: Int
        var updatedAt: Int
        var attributes: [String: String]
        var floorValue: Double
        var status: BedBoardBatchStatus

        init(code: String, title: String, checksum: String, discount: Double, phone: String, acuity: Int, retries: Int, attempts: Int, updatedAt: Int, attributes: [String: String], floorValue: Double, status: BedBoardBatchStatus) {
            self.code = code
            self.title = title
            self.checksum = checksum
            self.discount = discount
            self.phone = phone
            self.acuity = acuity
            self.retries = retries
            self.attempts = attempts
            self.updatedAt = updatedAt
            self.attributes = attributes
            self.floorValue = floorValue
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BedBoardBatchStatus) -> Bool {
            switch status {
            case .planned:
                return next == BedBoardBatchStatus.scheduled
            case .scheduled:
                return next == BedBoardBatchStatus.completed || next == BedBoardBatchStatus.cancelled
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: BedBoardBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("bed board batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("bed board batch") \(code)"
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

        func netLoad() -> Double {
            return ((Double(attempts) + Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> BedBoardBatch {
            return BedBoardBatch(
                code: code,
                title: title,
                checksum: checksum,
                discount: discount,
                phone: phone,
                acuity: acuity,
                retries: retries,
                attempts: attempts,
                updatedAt: updatedAt,
                attributes: attributes,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a bed board batch in status planned.
    static func newBedBoardBatch(_ code: String, title: String) -> BedBoardBatch {
        return BedBoardBatch(
            code: code,
            title: title,
            checksum: "",
            discount: 0.0,
            phone: "",
            acuity: 0,
            retries: 0,
            attempts: 0,
            updatedAt: 0,
            attributes: [:],
            floorValue: 0.0,
            status: BedBoardBatchStatus.planned
        )
    }
}
