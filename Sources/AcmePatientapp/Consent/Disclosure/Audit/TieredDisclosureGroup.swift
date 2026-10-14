import AcmePlatform
import Foundation

extension Consent {
    /// Where a tiered disclosure group is in its life cycle.
    enum TieredDisclosureGroupStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a tiered disclosure group and its current status.
    final class TieredDisclosureGroup {
        var code: String
        var name: String
        var country: String
        var diagnosisCode: String
        var externalRef: String
        var active: Bool
        var score: Double
        var status: TieredDisclosureGroupStatus

        init(code: String, name: String, country: String, diagnosisCode: String, externalRef: String, active: Bool, score: Double, status: TieredDisclosureGroupStatus) {
            self.code = code
            self.name = name
            self.country = country
            self.diagnosisCode = diagnosisCode
            self.externalRef = externalRef
            self.active = active
            self.score = score
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

        func canMoveTo(_ next: TieredDisclosureGroupStatus) -> Bool {
            switch status {
            case .proposed:
                return next == TieredDisclosureGroupStatus.rejected
            case .approved:
                return next == TieredDisclosureGroupStatus.rejected || next == TieredDisclosureGroupStatus.withdrawn
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

        func moveTo(_ next: TieredDisclosureGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered disclosure group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("tiered disclosure group") \(code)"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> TieredDisclosureGroup {
            return TieredDisclosureGroup(
                code: code,
                name: name,
                country: country,
                diagnosisCode: diagnosisCode,
                externalRef: externalRef,
                active: active,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a tiered disclosure group in status proposed.
    static func newTieredDisclosureGroup(_ code: String, name: String) -> TieredDisclosureGroup {
        return TieredDisclosureGroup(
            code: code,
            name: name,
            country: "",
            diagnosisCode: "",
            externalRef: "",
            active: false,
            score: 0.0,
            status: TieredDisclosureGroupStatus.proposed
        )
    }
}
