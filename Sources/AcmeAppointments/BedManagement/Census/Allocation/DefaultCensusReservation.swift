import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a default census reservation is in its life cycle.
    enum DefaultCensusReservationStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a default census reservation and its current status.
    final class DefaultCensusReservation {
        var code: String
        var name: String
        var procedureCode: String
        var margin: Double
        var version: Int
        var startsAt: Int
        var graceDays: Int
        var priority: Int
        var segment: String
        var windowDays: Int
        var threshold: Double
        var status: DefaultCensusReservationStatus

        init(code: String, name: String, procedureCode: String, margin: Double, version: Int, startsAt: Int, graceDays: Int, priority: Int, segment: String, windowDays: Int, threshold: Double, status: DefaultCensusReservationStatus) {
            self.code = code
            self.name = name
            self.procedureCode = procedureCode
            self.margin = margin
            self.version = version
            self.startsAt = startsAt
            self.graceDays = graceDays
            self.priority = priority
            self.segment = segment
            self.windowDays = windowDays
            self.threshold = threshold
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

        func canMoveTo(_ next: DefaultCensusReservationStatus) -> Bool {
            switch status {
            case .new:
                return next == DefaultCensusReservationStatus.running || next == DefaultCensusReservationStatus.done
            case .queued:
                return next == DefaultCensusReservationStatus.done || next == DefaultCensusReservationStatus.failed
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

        func moveTo(_ next: DefaultCensusReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default census reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func adjustedValue() -> Double {
            return ((threshold - Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultCensusReservation {
            return DefaultCensusReservation(
                code: code,
                name: name,
                procedureCode: procedureCode,
                margin: margin,
                version: version,
                startsAt: startsAt,
                graceDays: graceDays,
                priority: priority,
                segment: segment,
                windowDays: windowDays,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a default census reservation in status new.
    static func newDefaultCensusReservation(_ code: String, name: String) -> DefaultCensusReservation {
        return DefaultCensusReservation(
            code: code,
            name: name,
            procedureCode: "",
            margin: 0.0,
            version: 0,
            startsAt: 0,
            graceDays: 0,
            priority: 0,
            segment: "",
            windowDays: 0,
            threshold: 0.0,
            status: DefaultCensusReservationStatus.new
        )
    }
}
