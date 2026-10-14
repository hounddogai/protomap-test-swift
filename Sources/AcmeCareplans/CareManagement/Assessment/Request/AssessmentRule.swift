import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a assessment rule is in its life cycle.
    enum AssessmentRuleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A assessment rule. Its code is unique within a tenant.
    final class AssessmentRule {
        var code: String
        var label: String
        var version: Int
        var title: String
        var ratio: Double
        var ward: String
        var visitMinutes: Int
        var createdAt: Int
        var ownerID: String
        var active: Bool
        var status: AssessmentRuleStatus

        init(code: String, label: String, version: Int, title: String, ratio: Double, ward: String, visitMinutes: Int, createdAt: Int, ownerID: String, active: Bool, status: AssessmentRuleStatus) {
            self.code = code
            self.label = label
            self.version = version
            self.title = title
            self.ratio = ratio
            self.ward = ward
            self.visitMinutes = visitMinutes
            self.createdAt = createdAt
            self.ownerID = ownerID
            self.active = active
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

        func canMoveTo(_ next: AssessmentRuleStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == AssessmentRuleStatus.done
            case .running:
                return next == AssessmentRuleStatus.done || next == AssessmentRuleStatus.failed
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

        func moveTo(_ next: AssessmentRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("assessment rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func projectedVolume() -> Double {
            return ((Double(createdAt) + Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> AssessmentRule {
            return AssessmentRule(
                code: code,
                label: label,
                version: version,
                title: title,
                ratio: ratio,
                ward: ward,
                visitMinutes: visitMinutes,
                createdAt: createdAt,
                ownerID: ownerID,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a assessment rule in status new.
    static func newAssessmentRule(_ code: String, label: String) -> AssessmentRule {
        return AssessmentRule(
            code: code,
            label: label,
            version: 0,
            title: "",
            ratio: 0.0,
            ward: "",
            visitMinutes: 0,
            createdAt: 0,
            ownerID: "",
            active: false,
            status: AssessmentRuleStatus.new
        )
    }
}
