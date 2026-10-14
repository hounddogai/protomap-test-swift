import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a regional statement reservation is in its life cycle.
    enum RegionalStatementReservationStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One regional statement reservation, with what the planners need to act on it.
    final class RegionalStatementReservation {
        var code: String
        var label: String
        var archived: Bool
        var limit: Int
        var diagnosisCode: String
        var tags: [String]
        var retries: Int
        var maximum: Double
        var pinned: Bool
        var status: RegionalStatementReservationStatus

        init(code: String, label: String, archived: Bool, limit: Int, diagnosisCode: String, tags: [String], retries: Int, maximum: Double, pinned: Bool, status: RegionalStatementReservationStatus) {
            self.code = code
            self.label = label
            self.archived = archived
            self.limit = limit
            self.diagnosisCode = diagnosisCode
            self.tags = tags
            self.retries = retries
            self.maximum = maximum
            self.pinned = pinned
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

        func canMoveTo(_ next: RegionalStatementReservationStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready:
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
                return next == RegionalStatementReservationStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalStatementReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional statement reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedExposure() -> Double {
            return (Double(retries) * Double(limit) * 100).rounded() / 100
        }

        func copyValue() -> RegionalStatementReservation {
            return RegionalStatementReservation(
                code: code,
                label: label,
                archived: archived,
                limit: limit,
                diagnosisCode: diagnosisCode,
                tags: tags,
                retries: retries,
                maximum: maximum,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a regional statement reservation in status idle.
    static func newRegionalStatementReservation(_ code: String, label: String) -> RegionalStatementReservation {
        return RegionalStatementReservation(
            code: code,
            label: label,
            archived: false,
            limit: 0,
            diagnosisCode: "",
            tags: [],
            retries: 0,
            maximum: 0.0,
            pinned: false,
            status: RegionalStatementReservationStatus.idle
        )
    }
}
