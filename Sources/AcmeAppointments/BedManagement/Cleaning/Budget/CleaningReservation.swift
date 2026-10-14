import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a cleaning reservation is in its life cycle.
    enum CleaningReservationStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One cleaning reservation, with what the planners need to act on it.
    final class CleaningReservation {
        var code: String
        var title: String
        var allergy: String
        var visible: Bool
        var updatedAt: Int
        var retries: Int
        var currency: String
        var unit: String
        var status: CleaningReservationStatus

        init(code: String, title: String, allergy: String, visible: Bool, updatedAt: Int, retries: Int, currency: String, unit: String, status: CleaningReservationStatus) {
            self.code = code
            self.title = title
            self.allergy = allergy
            self.visible = visible
            self.updatedAt = updatedAt
            self.retries = retries
            self.currency = currency
            self.unit = unit
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

        func canMoveTo(_ next: CleaningReservationStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == CleaningReservationStatus.done || next == CleaningReservationStatus.failed
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

        func moveTo(_ next: CleaningReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("cleaning reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func weightedLoad() -> Double {
            return (Double(retries) * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> CleaningReservation {
            return CleaningReservation(
                code: code,
                title: title,
                allergy: allergy,
                visible: visible,
                updatedAt: updatedAt,
                retries: retries,
                currency: currency,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a cleaning reservation in status new.
    static func newCleaningReservation(_ code: String, title: String) -> CleaningReservation {
        return CleaningReservation(
            code: code,
            title: title,
            allergy: "",
            visible: false,
            updatedAt: 0,
            retries: 0,
            currency: "",
            unit: "",
            status: CleaningReservationStatus.new
        )
    }
}
