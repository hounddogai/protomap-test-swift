import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a adaptive discharge plan mapping is in its life cycle.
    enum AdaptiveDischargePlanMappingStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A adaptive discharge plan mapping as the discharge plan team keeps it.
    final class AdaptiveDischargePlanMapping {
        var code: String
        var name: String
        var procedureCode: String
        var attributes: [String: String]
        var minimum: Double
        var region: String
        var status: AdaptiveDischargePlanMappingStatus

        init(code: String, name: String, procedureCode: String, attributes: [String: String], minimum: Double, region: String, status: AdaptiveDischargePlanMappingStatus) {
            self.code = code
            self.name = name
            self.procedureCode = procedureCode
            self.attributes = attributes
            self.minimum = minimum
            self.region = region
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AdaptiveDischargePlanMappingStatus) -> Bool {
            switch status {
            case .draft:
                return next == AdaptiveDischargePlanMappingStatus.active
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == AdaptiveDischargePlanMappingStatus.suspended
            case .suspended:
                return next == AdaptiveDischargePlanMappingStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveDischargePlanMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive discharge plan mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("adaptive discharge plan mapping") \(code)"
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

        func measuredValue() -> Double {
            return minimum
        }

        func copyValue() -> AdaptiveDischargePlanMapping {
            return AdaptiveDischargePlanMapping(
                code: code,
                name: name,
                procedureCode: procedureCode,
                attributes: attributes,
                minimum: minimum,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a adaptive discharge plan mapping in status draft.
    static func newAdaptiveDischargePlanMapping(_ code: String, name: String) -> AdaptiveDischargePlanMapping {
        return AdaptiveDischargePlanMapping(
            code: code,
            name: name,
            procedureCode: "",
            attributes: [:],
            minimum: 0.0,
            region: "",
            status: AdaptiveDischargePlanMappingStatus.draft
        )
    }
}
