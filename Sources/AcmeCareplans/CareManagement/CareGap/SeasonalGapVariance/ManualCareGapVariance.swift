import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a manual care gap variance is in its life cycle.
    enum ManualCareGapVarianceStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a manual care gap variance and its current status.
    final class ManualCareGapVariance {
        var code: String
        var title: String
        var externalRef: String
        var procedureCode: String
        var ward: String
        var ownerID: String
        var facility: String
        var visible: Bool
        var quantity: Int
        var status: ManualCareGapVarianceStatus

        init(code: String, title: String, externalRef: String, procedureCode: String, ward: String, ownerID: String, facility: String, visible: Bool, quantity: Int, status: ManualCareGapVarianceStatus) {
            self.code = code
            self.title = title
            self.externalRef = externalRef
            self.procedureCode = procedureCode
            self.ward = ward
            self.ownerID = ownerID
            self.facility = facility
            self.visible = visible
            self.quantity = quantity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ManualCareGapVarianceStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: ManualCareGapVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual care gap variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> ManualCareGapVariance {
            return ManualCareGapVariance(
                code: code,
                title: title,
                externalRef: externalRef,
                procedureCode: procedureCode,
                ward: ward,
                ownerID: ownerID,
                facility: facility,
                visible: visible,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a manual care gap variance in status created.
    static func newManualCareGapVariance(_ code: String, title: String) -> ManualCareGapVariance {
        return ManualCareGapVariance(
            code: code,
            title: title,
            externalRef: "",
            procedureCode: "",
            ward: "",
            ownerID: "",
            facility: "",
            visible: false,
            quantity: 0,
            status: ManualCareGapVarianceStatus.created
        )
    }
}
