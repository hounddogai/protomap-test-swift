import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a risk score exception is in its life cycle.
    enum RiskScoreExceptionStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A risk score exception as the risk score team keeps it.
    final class RiskScoreException {
        var code: String
        var title: String
        var facility: String
        var version: Int
        var visitMinutes: Int
        var source: String
        var specialty: String
        var acuity: Int
        var checksum: String
        var category: String
        var endsAt: Int
        var status: RiskScoreExceptionStatus

        init(code: String, title: String, facility: String, version: Int, visitMinutes: Int, source: String, specialty: String, acuity: Int, checksum: String, category: String, endsAt: Int, status: RiskScoreExceptionStatus) {
            self.code = code
            self.title = title
            self.facility = facility
            self.version = version
            self.visitMinutes = visitMinutes
            self.source = source
            self.specialty = specialty
            self.acuity = acuity
            self.checksum = checksum
            self.category = category
            self.endsAt = endsAt
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

        func canMoveTo(_ next: RiskScoreExceptionStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining, .stopped:
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
                return next == RiskScoreExceptionStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RiskScoreExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("risk score exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func adjustedVolume() -> Double {
            return ((Double(acuity) + Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> RiskScoreException {
            return RiskScoreException(
                code: code,
                title: title,
                facility: facility,
                version: version,
                visitMinutes: visitMinutes,
                source: source,
                specialty: specialty,
                acuity: acuity,
                checksum: checksum,
                category: category,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a risk score exception in status idle.
    static func newRiskScoreException(_ code: String, title: String) -> RiskScoreException {
        return RiskScoreException(
            code: code,
            title: title,
            facility: "",
            version: 0,
            visitMinutes: 0,
            source: "",
            specialty: "",
            acuity: 0,
            checksum: "",
            category: "",
            endsAt: 0,
            status: RiskScoreExceptionStatus.idle
        )
    }
}
