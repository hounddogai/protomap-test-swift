import AcmePlatform
import Foundation

extension Imaging {
    /// Where a modality estimate is in its life cycle.
    enum ModalityEstimateStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A modality estimate. Its code is unique within a tenant.
    final class ModalityEstimate {
        var code: String
        var label: String
        var weight: Double
        var ward: String
        var description: String
        var country: String
        var status: ModalityEstimateStatus

        init(code: String, label: String, weight: Double, ward: String, description: String, country: String, status: ModalityEstimateStatus) {
            self.code = code
            self.label = label
            self.weight = weight
            self.ward = ward
            self.description = description
            self.country = country
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ModalityEstimateStatus) -> Bool {
            switch status {
            case .idle:
                return next == ModalityEstimateStatus.warming || next == ModalityEstimateStatus.draining
            case .warming:
                return next == ModalityEstimateStatus.ready || next == ModalityEstimateStatus.draining
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == ModalityEstimateStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ModalityEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("modality estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("modality estimate") \(code)"
        }

        func measuredValue() -> Double {
            return weight
        }

        func copyValue() -> ModalityEstimate {
            return ModalityEstimate(
                code: code,
                label: label,
                weight: weight,
                ward: ward,
                description: description,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a modality estimate in status idle.
    static func newModalityEstimate(_ code: String, label: String) -> ModalityEstimate {
        return ModalityEstimate(
            code: code,
            label: label,
            weight: 0.0,
            ward: "",
            description: "",
            country: "",
            status: ModalityEstimateStatus.idle
        )
    }
}
