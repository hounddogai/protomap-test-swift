import AcmePlatform
import Foundation

extension Labs {
    /// Where a regional reference range mapping is in its life cycle.
    enum RegionalReferenceRangeMappingStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One regional reference range mapping, with what the planners need to act on it.
    final class RegionalReferenceRangeMapping {
        var code: String
        var name: String
        var procedureCode: String
        var threshold: Double
        var copay: Double
        var acuity: Int
        var status: RegionalReferenceRangeMappingStatus

        init(code: String, name: String, procedureCode: String, threshold: Double, copay: Double, acuity: Int, status: RegionalReferenceRangeMappingStatus) {
            self.code = code
            self.name = name
            self.procedureCode = procedureCode
            self.threshold = threshold
            self.copay = copay
            self.acuity = acuity
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

        func canMoveTo(_ next: RegionalReferenceRangeMappingStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == RegionalReferenceRangeMappingStatus.withdrawn
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

        func moveTo(_ next: RegionalReferenceRangeMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional reference range mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func netVolume() -> Double {
            return ((copay + threshold) * 100).rounded() / 100
        }

        func copyValue() -> RegionalReferenceRangeMapping {
            return RegionalReferenceRangeMapping(
                code: code,
                name: name,
                procedureCode: procedureCode,
                threshold: threshold,
                copay: copay,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a regional reference range mapping in status proposed.
    static func newRegionalReferenceRangeMapping(_ code: String, name: String) -> RegionalReferenceRangeMapping {
        return RegionalReferenceRangeMapping(
            code: code,
            name: name,
            procedureCode: "",
            threshold: 0.0,
            copay: 0.0,
            acuity: 0,
            status: RegionalReferenceRangeMappingStatus.proposed
        )
    }
}
