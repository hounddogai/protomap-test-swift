import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a bed board record is in its life cycle.
    enum BedBoardRecordStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A bed board record. Its code is unique within a tenant.
    final class BedBoardRecord {
        var code: String
        var title: String
        var timezone: String
        var contactEmail: String
        var floorValue: Double
        var description: String
        var createdAt: Int
        var status: BedBoardRecordStatus

        init(code: String, title: String, timezone: String, contactEmail: String, floorValue: Double, description: String, createdAt: Int, status: BedBoardRecordStatus) {
            self.code = code
            self.title = title
            self.timezone = timezone
            self.contactEmail = contactEmail
            self.floorValue = floorValue
            self.description = description
            self.createdAt = createdAt
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

        func canMoveTo(_ next: BedBoardRecordStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == BedBoardRecordStatus.running || next == BedBoardRecordStatus.done
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == BedBoardRecordStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BedBoardRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("bed board record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func projectedLoad() -> Double {
            return ((Double(createdAt) - floorValue) * 100).rounded() / 100
        }

        func copyValue() -> BedBoardRecord {
            return BedBoardRecord(
                code: code,
                title: title,
                timezone: timezone,
                contactEmail: contactEmail,
                floorValue: floorValue,
                description: description,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a bed board record in status new.
    static func newBedBoardRecord(_ code: String, title: String) -> BedBoardRecord {
        return BedBoardRecord(
            code: code,
            title: title,
            timezone: "",
            contactEmail: "",
            floorValue: 0.0,
            description: "",
            createdAt: 0,
            status: BedBoardRecordStatus.new
        )
    }
}
