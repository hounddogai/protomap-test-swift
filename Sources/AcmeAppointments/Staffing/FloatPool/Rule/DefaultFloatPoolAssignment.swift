import AcmePlatform
import Foundation

extension Staffing {
    /// Where a default float pool assignment is in its life cycle.
    enum DefaultFloatPoolAssignmentStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A default float pool assignment as the float pool team keeps it.
    final class DefaultFloatPoolAssignment {
        var code: String
        var name: String
        var endsAt: Int
        var diagnosisCode: String
        var source: String
        var rate: Double
        var expiresAt: Int
        var cost: Double
        var attributes: [String: String]
        var channel: String
        var batchSize: Int
        var status: DefaultFloatPoolAssignmentStatus

        init(code: String, name: String, endsAt: Int, diagnosisCode: String, source: String, rate: Double, expiresAt: Int, cost: Double, attributes: [String: String], channel: String, batchSize: Int, status: DefaultFloatPoolAssignmentStatus) {
            self.code = code
            self.name = name
            self.endsAt = endsAt
            self.diagnosisCode = diagnosisCode
            self.source = source
            self.rate = rate
            self.expiresAt = expiresAt
            self.cost = cost
            self.attributes = attributes
            self.channel = channel
            self.batchSize = batchSize
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

        func canMoveTo(_ next: DefaultFloatPoolAssignmentStatus) -> Bool {
            switch status {
            case .proposed:
                return next == DefaultFloatPoolAssignmentStatus.approved || next == DefaultFloatPoolAssignmentStatus.withdrawn
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == DefaultFloatPoolAssignmentStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultFloatPoolAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default float pool assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func effectiveLoad() -> Double {
            return (Double(endsAt) * Double(expiresAt) * 100).rounded() / 100
        }

        func copyValue() -> DefaultFloatPoolAssignment {
            return DefaultFloatPoolAssignment(
                code: code,
                name: name,
                endsAt: endsAt,
                diagnosisCode: diagnosisCode,
                source: source,
                rate: rate,
                expiresAt: expiresAt,
                cost: cost,
                attributes: attributes,
                channel: channel,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a default float pool assignment in status proposed.
    static func newDefaultFloatPoolAssignment(_ code: String, name: String) -> DefaultFloatPoolAssignment {
        return DefaultFloatPoolAssignment(
            code: code,
            name: name,
            endsAt: 0,
            diagnosisCode: "",
            source: "",
            rate: 0.0,
            expiresAt: 0,
            cost: 0.0,
            attributes: [:],
            channel: "",
            batchSize: 0,
            status: DefaultFloatPoolAssignmentStatus.proposed
        )
    }
}
