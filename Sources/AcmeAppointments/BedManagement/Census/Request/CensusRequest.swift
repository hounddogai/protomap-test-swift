import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a census request is in its life cycle.
    enum CensusRequestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A census request. Its code is unique within a tenant.
    final class CensusRequest {
        var code: String
        var label: String
        var segment: String
        var margin: Double
        var ward: String
        var attributes: [String: String]
        var summary: String
        var diagnosisCode: String
        var status: CensusRequestStatus

        init(code: String, label: String, segment: String, margin: Double, ward: String, attributes: [String: String], summary: String, diagnosisCode: String, status: CensusRequestStatus) {
            self.code = code
            self.label = label
            self.segment = segment
            self.margin = margin
            self.ward = ward
            self.attributes = attributes
            self.summary = summary
            self.diagnosisCode = diagnosisCode
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

        func canMoveTo(_ next: CensusRequestStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: CensusRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("census request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
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
            return margin
        }

        func copyValue() -> CensusRequest {
            return CensusRequest(
                code: code,
                label: label,
                segment: segment,
                margin: margin,
                ward: ward,
                attributes: attributes,
                summary: summary,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a census request in status draft.
    static func newCensusRequest(_ code: String, label: String) -> CensusRequest {
        return CensusRequest(
            code: code,
            label: label,
            segment: "",
            margin: 0.0,
            ward: "",
            attributes: [:],
            summary: "",
            diagnosisCode: "",
            status: CensusRequestStatus.draft
        )
    }
}
