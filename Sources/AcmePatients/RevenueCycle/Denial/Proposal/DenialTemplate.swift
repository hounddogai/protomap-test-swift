import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a denial template is in its life cycle.
    enum DenialTemplateStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A denial template. Its code is unique within a tenant.
    final class DenialTemplate {
        var code: String
        var title: String
        var channel: String
        var expiresAt: Int
        var diagnosisCode: String
        var source: String
        var name: String
        var active: Bool
        var clinicianID: String
        var status: DenialTemplateStatus

        init(code: String, title: String, channel: String, expiresAt: Int, diagnosisCode: String, source: String, name: String, active: Bool, clinicianID: String, status: DenialTemplateStatus) {
            self.code = code
            self.title = title
            self.channel = channel
            self.expiresAt = expiresAt
            self.diagnosisCode = diagnosisCode
            self.source = source
            self.name = name
            self.active = active
            self.clinicianID = clinicianID
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

        func canMoveTo(_ next: DenialTemplateStatus) -> Bool {
            switch status {
            case .proposed:
                return next == DenialTemplateStatus.withdrawn
            case .approved:
                return next == DenialTemplateStatus.rejected || next == DenialTemplateStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: DenialTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("denial template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("denial template") \(code)"
        }

        func measuredValue() -> Double {
            return Double(expiresAt)
        }

        func copyValue() -> DenialTemplate {
            return DenialTemplate(
                code: code,
                title: title,
                channel: channel,
                expiresAt: expiresAt,
                diagnosisCode: diagnosisCode,
                source: source,
                name: name,
                active: active,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a denial template in status proposed.
    static func newDenialTemplate(_ code: String, title: String) -> DenialTemplate {
        return DenialTemplate(
            code: code,
            title: title,
            channel: "",
            expiresAt: 0,
            diagnosisCode: "",
            source: "",
            name: "",
            active: false,
            clinicianID: "",
            status: DenialTemplateStatus.proposed
        )
    }
}
