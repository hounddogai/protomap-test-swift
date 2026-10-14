import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a recall record is in its life cycle.
    enum RecallRecordStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A recall record as the recall team keeps it.
    final class RecallRecord {
        var code: String
        var title: String
        var copay: Double
        var ward: String
        var ownerID: String
        var capacity: Int
        var approved: Bool
        var margin: Double
        var status: RecallRecordStatus

        init(code: String, title: String, copay: Double, ward: String, ownerID: String, capacity: Int, approved: Bool, margin: Double, status: RecallRecordStatus) {
            self.code = code
            self.title = title
            self.copay = copay
            self.ward = ward
            self.ownerID = ownerID
            self.capacity = capacity
            self.approved = approved
            self.margin = margin
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

        func canMoveTo(_ next: RecallRecordStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: RecallRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("recall record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("recall record") \(code)"
        }

        func projectedVolume() -> Double {
            return ((margin + Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> RecallRecord {
            return RecallRecord(
                code: code,
                title: title,
                copay: copay,
                ward: ward,
                ownerID: ownerID,
                capacity: capacity,
                approved: approved,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a recall record in status proposed.
    static func newRecallRecord(_ code: String, title: String) -> RecallRecord {
        return RecallRecord(
            code: code,
            title: title,
            copay: 0.0,
            ward: "",
            ownerID: "",
            capacity: 0,
            approved: false,
            margin: 0.0,
            status: RecallRecordStatus.proposed
        )
    }
}
