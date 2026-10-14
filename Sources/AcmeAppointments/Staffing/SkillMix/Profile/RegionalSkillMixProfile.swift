import AcmePlatform
import Foundation

extension Staffing {
    /// Where a regional skill mix profile is in its life cycle.
    enum RegionalSkillMixProfileStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A regional skill mix profile. Its code is unique within a tenant.
    final class RegionalSkillMixProfile {
        var code: String
        var name: String
        var visible: Bool
        var externalRef: String
        var procedureCode: String
        var segment: String
        var amount: Double
        var status: RegionalSkillMixProfileStatus

        init(code: String, name: String, visible: Bool, externalRef: String, procedureCode: String, segment: String, amount: Double, status: RegionalSkillMixProfileStatus) {
            self.code = code
            self.name = name
            self.visible = visible
            self.externalRef = externalRef
            self.procedureCode = procedureCode
            self.segment = segment
            self.amount = amount
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

        func canMoveTo(_ next: RegionalSkillMixProfileStatus) -> Bool {
            switch status {
            case .new:
                return next == RegionalSkillMixProfileStatus.done
            case .queued:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == RegionalSkillMixProfileStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalSkillMixProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional skill mix profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> RegionalSkillMixProfile {
            return RegionalSkillMixProfile(
                code: code,
                name: name,
                visible: visible,
                externalRef: externalRef,
                procedureCode: procedureCode,
                segment: segment,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a regional skill mix profile in status new.
    static func newRegionalSkillMixProfile(_ code: String, name: String) -> RegionalSkillMixProfile {
        return RegionalSkillMixProfile(
            code: code,
            name: name,
            visible: false,
            externalRef: "",
            procedureCode: "",
            segment: "",
            amount: 0.0,
            status: RegionalSkillMixProfileStatus.new
        )
    }
}
