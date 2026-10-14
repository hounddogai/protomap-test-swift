import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a global risk score audit is in its life cycle.
    enum GlobalRiskScoreAuditStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A global risk score audit. Its code is unique within a tenant.
    final class GlobalRiskScoreAudit {
        var code: String
        var name: String
        var refills: Int
        var patientRef: String
        var visitMinutes: Int
        var score: Double
        var unit: String
        var archived: Bool
        var version: Int
        var status: GlobalRiskScoreAuditStatus

        init(code: String, name: String, refills: Int, patientRef: String, visitMinutes: Int, score: Double, unit: String, archived: Bool, version: Int, status: GlobalRiskScoreAuditStatus) {
            self.code = code
            self.name = name
            self.refills = refills
            self.patientRef = patientRef
            self.visitMinutes = visitMinutes
            self.score = score
            self.unit = unit
            self.archived = archived
            self.version = version
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

        func canMoveTo(_ next: GlobalRiskScoreAuditStatus) -> Bool {
            switch status {
            case .new:
                return next == GlobalRiskScoreAuditStatus.failed
            case .queued:
                return next == GlobalRiskScoreAuditStatus.done || next == GlobalRiskScoreAuditStatus.failed
            case .running:
                switch next {
                case .done, .failed:
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

        func moveTo(_ next: GlobalRiskScoreAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global risk score audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func netValue() -> Double {
            return ((Double(visitMinutes) - Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalRiskScoreAudit {
            return GlobalRiskScoreAudit(
                code: code,
                name: name,
                refills: refills,
                patientRef: patientRef,
                visitMinutes: visitMinutes,
                score: score,
                unit: unit,
                archived: archived,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a global risk score audit in status new.
    static func newGlobalRiskScoreAudit(_ code: String, name: String) -> GlobalRiskScoreAudit {
        return GlobalRiskScoreAudit(
            code: code,
            name: name,
            refills: 0,
            patientRef: "",
            visitMinutes: 0,
            score: 0.0,
            unit: "",
            archived: false,
            version: 0,
            status: GlobalRiskScoreAuditStatus.new
        )
    }
}
