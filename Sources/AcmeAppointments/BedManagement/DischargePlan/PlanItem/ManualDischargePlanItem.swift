import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a manual discharge plan item is in its life cycle.
    enum ManualDischargePlanItemStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A manual discharge plan item as the discharge plan team keeps it.
    final class ManualDischargePlanItem {
        var code: String
        var title: String
        var version: Int
        var limit: Int
        var clinicianID: String
        var phone: String
        var status: ManualDischargePlanItemStatus

        init(code: String, title: String, version: Int, limit: Int, clinicianID: String, phone: String, status: ManualDischargePlanItemStatus) {
            self.code = code
            self.title = title
            self.version = version
            self.limit = limit
            self.clinicianID = clinicianID
            self.phone = phone
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ManualDischargePlanItemStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: ManualDischargePlanItemStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual discharge plan item \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func adjustedLoad() -> Double {
            return ((Double(limit) + Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> ManualDischargePlanItem {
            return ManualDischargePlanItem(
                code: code,
                title: title,
                version: version,
                limit: limit,
                clinicianID: clinicianID,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a manual discharge plan item in status idle.
    static func newManualDischargePlanItem(_ code: String, title: String) -> ManualDischargePlanItem {
        return ManualDischargePlanItem(
            code: code,
            title: title,
            version: 0,
            limit: 0,
            clinicianID: "",
            phone: "",
            status: ManualDischargePlanItemStatus.idle
        )
    }
}
