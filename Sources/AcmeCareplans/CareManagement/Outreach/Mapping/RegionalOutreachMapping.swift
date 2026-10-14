import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a regional outreach mapping is in its life cycle.
    enum RegionalOutreachMappingStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One regional outreach mapping, with what the planners need to act on it.
    final class RegionalOutreachMapping {
        var code: String
        var title: String
        var rate: Double
        var discount: Double
        var facility: String
        var ratio: Double
        var region: String
        var diagnosisCode: String
        var attributes: [String: String]
        var status: RegionalOutreachMappingStatus

        init(code: String, title: String, rate: Double, discount: Double, facility: String, ratio: Double, region: String, diagnosisCode: String, attributes: [String: String], status: RegionalOutreachMappingStatus) {
            self.code = code
            self.title = title
            self.rate = rate
            self.discount = discount
            self.facility = facility
            self.ratio = ratio
            self.region = region
            self.diagnosisCode = diagnosisCode
            self.attributes = attributes
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

        func canMoveTo(_ next: RegionalOutreachMappingStatus) -> Bool {
            switch status {
            case .proposed:
                return next == RegionalOutreachMappingStatus.approved || next == RegionalOutreachMappingStatus.rejected
            case .approved:
                return next == RegionalOutreachMappingStatus.rejected
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

        func moveTo(_ next: RegionalOutreachMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional outreach mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
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

        func netVolume() -> Double {
            return (ratio * discount * 100).rounded() / 100
        }

        func copyValue() -> RegionalOutreachMapping {
            return RegionalOutreachMapping(
                code: code,
                title: title,
                rate: rate,
                discount: discount,
                facility: facility,
                ratio: ratio,
                region: region,
                diagnosisCode: diagnosisCode,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a regional outreach mapping in status proposed.
    static func newRegionalOutreachMapping(_ code: String, title: String) -> RegionalOutreachMapping {
        return RegionalOutreachMapping(
            code: code,
            title: title,
            rate: 0.0,
            discount: 0.0,
            facility: "",
            ratio: 0.0,
            region: "",
            diagnosisCode: "",
            attributes: [:],
            status: RegionalOutreachMappingStatus.proposed
        )
    }
}
