import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a rolling dispense agreement is in its life cycle.
    enum RollingDispenseAgreementStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One rolling dispense agreement, with what the planners need to act on it.
    final class RollingDispenseAgreement {
        var code: String
        var title: String
        var procedureCode: String
        var windowDays: Int
        var endsAt: Int
        var encounterID: String
        var quantity: Int
        var floorValue: Double
        var limit: Int
        var priority: Int
        var discount: Double
        var status: RollingDispenseAgreementStatus

        init(code: String, title: String, procedureCode: String, windowDays: Int, endsAt: Int, encounterID: String, quantity: Int, floorValue: Double, limit: Int, priority: Int, discount: Double, status: RollingDispenseAgreementStatus) {
            self.code = code
            self.title = title
            self.procedureCode = procedureCode
            self.windowDays = windowDays
            self.endsAt = endsAt
            self.encounterID = encounterID
            self.quantity = quantity
            self.floorValue = floorValue
            self.limit = limit
            self.priority = priority
            self.discount = discount
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

        func canMoveTo(_ next: RollingDispenseAgreementStatus) -> Bool {
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
                return next == RollingDispenseAgreementStatus.done
            case .running:
                switch next {
                case .failed:
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

        func moveTo(_ next: RollingDispenseAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling dispense agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("rolling dispense agreement") \(code)"
        }

        func projectedVolume() -> Double {
            return (Double(windowDays) * Double(limit) * 100).rounded() / 100
        }

        func copyValue() -> RollingDispenseAgreement {
            return RollingDispenseAgreement(
                code: code,
                title: title,
                procedureCode: procedureCode,
                windowDays: windowDays,
                endsAt: endsAt,
                encounterID: encounterID,
                quantity: quantity,
                floorValue: floorValue,
                limit: limit,
                priority: priority,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a rolling dispense agreement in status new.
    static func newRollingDispenseAgreement(_ code: String, title: String) -> RollingDispenseAgreement {
        return RollingDispenseAgreement(
            code: code,
            title: title,
            procedureCode: "",
            windowDays: 0,
            endsAt: 0,
            encounterID: "",
            quantity: 0,
            floorValue: 0.0,
            limit: 0,
            priority: 0,
            discount: 0.0,
            status: RollingDispenseAgreementStatus.new
        )
    }
}
