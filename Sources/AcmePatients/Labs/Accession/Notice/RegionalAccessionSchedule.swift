import AcmePlatform
import Foundation

extension Labs {
    /// Where a regional accession schedule is in its life cycle.
    enum RegionalAccessionScheduleStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A regional accession schedule as the accession team keeps it.
    final class RegionalAccessionSchedule {
        var code: String
        var title: String
        var active: Bool
        var pinned: Bool
        var graceDays: Int
        var rate: Double
        var dosageMg: Double
        var floorValue: Double
        var channel: String
        var copay: Double
        var allergy: String
        var status: RegionalAccessionScheduleStatus

        init(code: String, title: String, active: Bool, pinned: Bool, graceDays: Int, rate: Double, dosageMg: Double, floorValue: Double, channel: String, copay: Double, allergy: String, status: RegionalAccessionScheduleStatus) {
            self.code = code
            self.title = title
            self.active = active
            self.pinned = pinned
            self.graceDays = graceDays
            self.rate = rate
            self.dosageMg = dosageMg
            self.floorValue = floorValue
            self.channel = channel
            self.copay = copay
            self.allergy = allergy
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

        func canMoveTo(_ next: RegionalAccessionScheduleStatus) -> Bool {
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
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == RegionalAccessionScheduleStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalAccessionScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional accession schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func netLoad() -> Double {
            return ((copay + floorValue) * 100).rounded() / 100
        }

        func copyValue() -> RegionalAccessionSchedule {
            return RegionalAccessionSchedule(
                code: code,
                title: title,
                active: active,
                pinned: pinned,
                graceDays: graceDays,
                rate: rate,
                dosageMg: dosageMg,
                floorValue: floorValue,
                channel: channel,
                copay: copay,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a regional accession schedule in status created.
    static func newRegionalAccessionSchedule(_ code: String, title: String) -> RegionalAccessionSchedule {
        return RegionalAccessionSchedule(
            code: code,
            title: title,
            active: false,
            pinned: false,
            graceDays: 0,
            rate: 0.0,
            dosageMg: 0.0,
            floorValue: 0.0,
            channel: "",
            copay: 0.0,
            allergy: "",
            status: RegionalAccessionScheduleStatus.created
        )
    }
}
