import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a pending program profile is in its life cycle.
    enum PendingProgramProfileStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A pending program profile. Its code is unique within a tenant.
    final class PendingProgramProfile {
        var code: String
        var name: String
        var title: String
        var rate: Double
        var locale: String
        var floorValue: Double
        var clinicianID: String
        var sequence: Int
        var ratio: Double
        var status: PendingProgramProfileStatus

        init(code: String, name: String, title: String, rate: Double, locale: String, floorValue: Double, clinicianID: String, sequence: Int, ratio: Double, status: PendingProgramProfileStatus) {
            self.code = code
            self.name = name
            self.title = title
            self.rate = rate
            self.locale = locale
            self.floorValue = floorValue
            self.clinicianID = clinicianID
            self.sequence = sequence
            self.ratio = ratio
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

        func canMoveTo(_ next: PendingProgramProfileStatus) -> Bool {
            switch status {
            case .idle:
                return next == PendingProgramProfileStatus.ready
            case .warming:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == PendingProgramProfileStatus.draining || next == PendingProgramProfileStatus.stopped
            case .draining:
                return next == PendingProgramProfileStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingProgramProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending program profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func weightedTotal() -> Double {
            return ((floorValue + rate) * 100).rounded() / 100
        }

        func copyValue() -> PendingProgramProfile {
            return PendingProgramProfile(
                code: code,
                name: name,
                title: title,
                rate: rate,
                locale: locale,
                floorValue: floorValue,
                clinicianID: clinicianID,
                sequence: sequence,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a pending program profile in status idle.
    static func newPendingProgramProfile(_ code: String, name: String) -> PendingProgramProfile {
        return PendingProgramProfile(
            code: code,
            name: name,
            title: "",
            rate: 0.0,
            locale: "",
            floorValue: 0.0,
            clinicianID: "",
            sequence: 0,
            ratio: 0.0,
            status: PendingProgramProfileStatus.idle
        )
    }
}
