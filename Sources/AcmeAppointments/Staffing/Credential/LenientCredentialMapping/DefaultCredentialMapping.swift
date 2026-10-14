import AcmePlatform
import Foundation

extension Staffing {
    /// Where a default credential mapping is in its life cycle.
    enum DefaultCredentialMappingStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One default credential mapping, with what the planners need to act on it.
    final class DefaultCredentialMapping {
        var code: String
        var name: String
        var floorValue: Double
        var limit: Int
        var specialty: String
        var diagnosisCode: String
        var rate: Double
        var status: DefaultCredentialMappingStatus

        init(code: String, name: String, floorValue: Double, limit: Int, specialty: String, diagnosisCode: String, rate: Double, status: DefaultCredentialMappingStatus) {
            self.code = code
            self.name = name
            self.floorValue = floorValue
            self.limit = limit
            self.specialty = specialty
            self.diagnosisCode = diagnosisCode
            self.rate = rate
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

        func canMoveTo(_ next: DefaultCredentialMappingStatus) -> Bool {
            switch status {
            case .idle:
                return next == DefaultCredentialMappingStatus.warming
            case .warming:
                return next == DefaultCredentialMappingStatus.stopped
            case .ready:
                return next == DefaultCredentialMappingStatus.draining
            case .draining:
                return next == DefaultCredentialMappingStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultCredentialMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default credential mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func projectedTotal() -> Double {
            return (floorValue * Double(limit) * 100).rounded() / 100
        }

        func copyValue() -> DefaultCredentialMapping {
            return DefaultCredentialMapping(
                code: code,
                name: name,
                floorValue: floorValue,
                limit: limit,
                specialty: specialty,
                diagnosisCode: diagnosisCode,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a default credential mapping in status idle.
    static func newDefaultCredentialMapping(_ code: String, name: String) -> DefaultCredentialMapping {
        return DefaultCredentialMapping(
            code: code,
            name: name,
            floorValue: 0.0,
            limit: 0,
            specialty: "",
            diagnosisCode: "",
            rate: 0.0,
            status: DefaultCredentialMappingStatus.idle
        )
    }
}
