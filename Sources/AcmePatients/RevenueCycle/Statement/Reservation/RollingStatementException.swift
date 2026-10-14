import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a rolling statement exception is in its life cycle.
    enum RollingStatementExceptionStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a rolling statement exception and its current status.
    final class RollingStatementException {
        var code: String
        var name: String
        var country: String
        var budget: Double
        var visible: Bool
        var capacity: Int
        var graceDays: Int
        var ratio: Double
        var startsAt: Int
        var locale: String
        var status: RollingStatementExceptionStatus

        init(code: String, name: String, country: String, budget: Double, visible: Bool, capacity: Int, graceDays: Int, ratio: Double, startsAt: Int, locale: String, status: RollingStatementExceptionStatus) {
            self.code = code
            self.name = name
            self.country = country
            self.budget = budget
            self.visible = visible
            self.capacity = capacity
            self.graceDays = graceDays
            self.ratio = ratio
            self.startsAt = startsAt
            self.locale = locale
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

        func canMoveTo(_ next: RollingStatementExceptionStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == RollingStatementExceptionStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingStatementExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling statement exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("rolling statement exception") \(code)"
        }

        func netTotal() -> Double {
            return ((ratio + Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> RollingStatementException {
            return RollingStatementException(
                code: code,
                name: name,
                country: country,
                budget: budget,
                visible: visible,
                capacity: capacity,
                graceDays: graceDays,
                ratio: ratio,
                startsAt: startsAt,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a rolling statement exception in status new.
    static func newRollingStatementException(_ code: String, name: String) -> RollingStatementException {
        return RollingStatementException(
            code: code,
            name: name,
            country: "",
            budget: 0.0,
            visible: false,
            capacity: 0,
            graceDays: 0,
            ratio: 0.0,
            startsAt: 0,
            locale: "",
            status: RollingStatementExceptionStatus.new
        )
    }
}
