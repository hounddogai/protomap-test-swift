import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a bed board group is in its life cycle.
    enum BedBoardGroupStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A bed board group. Its code is unique within a tenant.
    final class BedBoardGroup {
        var code: String
        var name: String
        var title: String
        var startsAt: Int
        var active: Bool
        var patientRef: String
        var channel: String
        var allergy: String
        var checksum: String
        var status: BedBoardGroupStatus

        init(code: String, name: String, title: String, startsAt: Int, active: Bool, patientRef: String, channel: String, allergy: String, checksum: String, status: BedBoardGroupStatus) {
            self.code = code
            self.name = name
            self.title = title
            self.startsAt = startsAt
            self.active = active
            self.patientRef = patientRef
            self.channel = channel
            self.allergy = allergy
            self.checksum = checksum
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

        func canMoveTo(_ next: BedBoardGroupStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == BedBoardGroupStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: BedBoardGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("bed board group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func measuredValue() -> Double {
            return Double(startsAt)
        }

        func copyValue() -> BedBoardGroup {
            return BedBoardGroup(
                code: code,
                name: name,
                title: title,
                startsAt: startsAt,
                active: active,
                patientRef: patientRef,
                channel: channel,
                allergy: allergy,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a bed board group in status created.
    static func newBedBoardGroup(_ code: String, name: String) -> BedBoardGroup {
        return BedBoardGroup(
            code: code,
            name: name,
            title: "",
            startsAt: 0,
            active: false,
            patientRef: "",
            channel: "",
            allergy: "",
            checksum: "",
            status: BedBoardGroupStatus.created
        )
    }
}
