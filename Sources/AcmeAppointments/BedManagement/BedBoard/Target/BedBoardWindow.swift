import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a bed board window is in its life cycle.
    enum BedBoardWindowStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a bed board window and its current status.
    final class BedBoardWindow {
        var code: String
        var title: String
        var visible: Bool
        var endsAt: Int
        var startsAt: Int
        var diagnosisCode: String
        var priority: Int
        var capacity: Int
        var clinicianID: String
        var externalRef: String
        var status: BedBoardWindowStatus

        init(code: String, title: String, visible: Bool, endsAt: Int, startsAt: Int, diagnosisCode: String, priority: Int, capacity: Int, clinicianID: String, externalRef: String, status: BedBoardWindowStatus) {
            self.code = code
            self.title = title
            self.visible = visible
            self.endsAt = endsAt
            self.startsAt = startsAt
            self.diagnosisCode = diagnosisCode
            self.priority = priority
            self.capacity = capacity
            self.clinicianID = clinicianID
            self.externalRef = externalRef
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

        func canMoveTo(_ next: BedBoardWindowStatus) -> Bool {
            switch status {
            case .proposed:
                return next == BedBoardWindowStatus.rejected || next == BedBoardWindowStatus.withdrawn
            case .approved:
                switch next {
                case .rejected:
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

        func moveTo(_ next: BedBoardWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("bed board window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func effectiveExposure() -> Double {
            return ((Double(startsAt) - Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> BedBoardWindow {
            return BedBoardWindow(
                code: code,
                title: title,
                visible: visible,
                endsAt: endsAt,
                startsAt: startsAt,
                diagnosisCode: diagnosisCode,
                priority: priority,
                capacity: capacity,
                clinicianID: clinicianID,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a bed board window in status proposed.
    static func newBedBoardWindow(_ code: String, title: String) -> BedBoardWindow {
        return BedBoardWindow(
            code: code,
            title: title,
            visible: false,
            endsAt: 0,
            startsAt: 0,
            diagnosisCode: "",
            priority: 0,
            capacity: 0,
            clinicianID: "",
            externalRef: "",
            status: BedBoardWindowStatus.proposed
        )
    }
}
