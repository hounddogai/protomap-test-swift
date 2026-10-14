import AcmePlatform
import Foundation

extension Staffing {
    /// Where a scheduled overtime record is in its life cycle.
    enum ScheduledOvertimeRecordStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One scheduled overtime record, with what the planners need to act on it.
    final class ScheduledOvertimeRecord {
        var code: String
        var label: String
        var facility: String
        var ratio: Double
        var ward: String
        var updatedAt: Int
        var tags: [String]
        var discount: Double
        var revision: Int
        var startsAt: Int
        var status: ScheduledOvertimeRecordStatus

        init(code: String, label: String, facility: String, ratio: Double, ward: String, updatedAt: Int, tags: [String], discount: Double, revision: Int, startsAt: Int, status: ScheduledOvertimeRecordStatus) {
            self.code = code
            self.label = label
            self.facility = facility
            self.ratio = ratio
            self.ward = ward
            self.updatedAt = updatedAt
            self.tags = tags
            self.discount = discount
            self.revision = revision
            self.startsAt = startsAt
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

        func canMoveTo(_ next: ScheduledOvertimeRecordStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == ScheduledOvertimeRecordStatus.withdrawn
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

        func moveTo(_ next: ScheduledOvertimeRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled overtime record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
            return "\("scheduled overtime record") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netValue() -> Double {
            return (discount * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledOvertimeRecord {
            return ScheduledOvertimeRecord(
                code: code,
                label: label,
                facility: facility,
                ratio: ratio,
                ward: ward,
                updatedAt: updatedAt,
                tags: tags,
                discount: discount,
                revision: revision,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a scheduled overtime record in status proposed.
    static func newScheduledOvertimeRecord(_ code: String, label: String) -> ScheduledOvertimeRecord {
        return ScheduledOvertimeRecord(
            code: code,
            label: label,
            facility: "",
            ratio: 0.0,
            ward: "",
            updatedAt: 0,
            tags: [],
            discount: 0.0,
            revision: 0,
            startsAt: 0,
            status: ScheduledOvertimeRecordStatus.proposed
        )
    }
}
