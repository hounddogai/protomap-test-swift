import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a risk score schedule is in its life cycle.
    enum RiskScoreScheduleStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a risk score schedule and its current status.
    final class RiskScoreSchedule {
        var code: String
        var name: String
        var patientRef: String
        var expiresAt: Int
        var attributes: [String: String]
        var bed: String
        var priority: Int
        var limit: Int
        var payer: String
        var unit: String
        var status: RiskScoreScheduleStatus

        init(code: String, name: String, patientRef: String, expiresAt: Int, attributes: [String: String], bed: String, priority: Int, limit: Int, payer: String, unit: String, status: RiskScoreScheduleStatus) {
            self.code = code
            self.name = name
            self.patientRef = patientRef
            self.expiresAt = expiresAt
            self.attributes = attributes
            self.bed = bed
            self.priority = priority
            self.limit = limit
            self.payer = payer
            self.unit = unit
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RiskScoreScheduleStatus) -> Bool {
            switch status {
            case .requested:
                return next == RiskScoreScheduleStatus.granted || next == RiskScoreScheduleStatus.expired
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == RiskScoreScheduleStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RiskScoreScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("risk score schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
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

        func projectedTotal() -> Double {
            return ((Double(expiresAt) + Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> RiskScoreSchedule {
            return RiskScoreSchedule(
                code: code,
                name: name,
                patientRef: patientRef,
                expiresAt: expiresAt,
                attributes: attributes,
                bed: bed,
                priority: priority,
                limit: limit,
                payer: payer,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a risk score schedule in status requested.
    static func newRiskScoreSchedule(_ code: String, name: String) -> RiskScoreSchedule {
        return RiskScoreSchedule(
            code: code,
            name: name,
            patientRef: "",
            expiresAt: 0,
            attributes: [:],
            bed: "",
            priority: 0,
            limit: 0,
            payer: "",
            unit: "",
            status: RiskScoreScheduleStatus.requested
        )
    }
}
