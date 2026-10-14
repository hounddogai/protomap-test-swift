import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a global statement reservation is in its life cycle.
    enum GlobalStatementReservationStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A global statement reservation as the statement team keeps it.
    final class GlobalStatementReservation {
        var code: String
        var label: String
        var limit: Int
        var createdAt: Int
        var startsAt: Int
        var rate: Double
        var phone: String
        var status: GlobalStatementReservationStatus

        init(code: String, label: String, limit: Int, createdAt: Int, startsAt: Int, rate: Double, phone: String, status: GlobalStatementReservationStatus) {
            self.code = code
            self.label = label
            self.limit = limit
            self.createdAt = createdAt
            self.startsAt = startsAt
            self.rate = rate
            self.phone = phone
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

        func canMoveTo(_ next: GlobalStatementReservationStatus) -> Bool {
            switch status {
            case .new:
                return next == GlobalStatementReservationStatus.running
            case .queued:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: GlobalStatementReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global statement reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("global statement reservation") \(code)"
        }

        func effectiveLoad() -> Double {
            return ((rate - Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalStatementReservation {
            return GlobalStatementReservation(
                code: code,
                label: label,
                limit: limit,
                createdAt: createdAt,
                startsAt: startsAt,
                rate: rate,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a global statement reservation in status new.
    static func newGlobalStatementReservation(_ code: String, label: String) -> GlobalStatementReservation {
        return GlobalStatementReservation(
            code: code,
            label: label,
            limit: 0,
            createdAt: 0,
            startsAt: 0,
            rate: 0.0,
            phone: "",
            status: GlobalStatementReservationStatus.new
        )
    }
}
