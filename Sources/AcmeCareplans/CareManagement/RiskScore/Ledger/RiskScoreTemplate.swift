import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a risk score template is in its life cycle.
    enum RiskScoreTemplateStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a risk score template and its current status.
    final class RiskScoreTemplate {
        var code: String
        var name: String
        var title: String
        var patientRef: String
        var visible: Bool
        var ratio: Double
        var priority: Int
        var source: String
        var status: RiskScoreTemplateStatus

        init(code: String, name: String, title: String, patientRef: String, visible: Bool, ratio: Double, priority: Int, source: String, status: RiskScoreTemplateStatus) {
            self.code = code
            self.name = name
            self.title = title
            self.patientRef = patientRef
            self.visible = visible
            self.ratio = ratio
            self.priority = priority
            self.source = source
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

        func canMoveTo(_ next: RiskScoreTemplateStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == RiskScoreTemplateStatus.running || next == RiskScoreTemplateStatus.failed
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

        func moveTo(_ next: RiskScoreTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("risk score template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func effectiveTotal() -> Double {
            return ((ratio + Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> RiskScoreTemplate {
            return RiskScoreTemplate(
                code: code,
                name: name,
                title: title,
                patientRef: patientRef,
                visible: visible,
                ratio: ratio,
                priority: priority,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a risk score template in status new.
    static func newRiskScoreTemplate(_ code: String, name: String) -> RiskScoreTemplate {
        return RiskScoreTemplate(
            code: code,
            name: name,
            title: "",
            patientRef: "",
            visible: false,
            ratio: 0.0,
            priority: 0,
            source: "",
            status: RiskScoreTemplateStatus.new
        )
    }
}
