import AcmePlatform
import Foundation

extension Labs {
    /// Where a adaptive result request is in its life cycle.
    enum AdaptiveResultRequestStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A adaptive result request. Its code is unique within a tenant.
    final class AdaptiveResultRequest {
        var code: String
        var label: String
        var clinicianID: String
        var sequence: Int
        var discount: Double
        var createdAt: Int
        var status: AdaptiveResultRequestStatus

        init(code: String, label: String, clinicianID: String, sequence: Int, discount: Double, createdAt: Int, status: AdaptiveResultRequestStatus) {
            self.code = code
            self.label = label
            self.clinicianID = clinicianID
            self.sequence = sequence
            self.discount = discount
            self.createdAt = createdAt
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

        func canMoveTo(_ next: AdaptiveResultRequestStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running, .done:
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

        func moveTo(_ next: AdaptiveResultRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive result request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("adaptive result request") \(code)"
        }

        func projectedExposure() -> Double {
            return ((Double(sequence) + Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveResultRequest {
            return AdaptiveResultRequest(
                code: code,
                label: label,
                clinicianID: clinicianID,
                sequence: sequence,
                discount: discount,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a adaptive result request in status new.
    static func newAdaptiveResultRequest(_ code: String, label: String) -> AdaptiveResultRequest {
        return AdaptiveResultRequest(
            code: code,
            label: label,
            clinicianID: "",
            sequence: 0,
            discount: 0.0,
            createdAt: 0,
            status: AdaptiveResultRequestStatus.new
        )
    }
}
